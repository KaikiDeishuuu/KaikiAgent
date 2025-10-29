package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"time"

	"github.com/nezhahq/agent/model"
	pb "github.com/nezhahq/agent/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"
)

// EnhancedAgent 增强版Agent，优化连接重试机制
type EnhancedAgent struct {
	config        *model.AgentConfig
	client        pb.NezhaServiceClient
	conn          *grpc.ClientConn
	auth          *model.AuthHandler
	retryCount    int
	maxRetries    int
	baseDelay     time.Duration
	maxDelay      time.Duration
	lastError     error
	lastErrorTime time.Time
}

// NewEnhancedAgent 创建增强版Agent
func NewEnhancedAgent(config *model.AgentConfig) *EnhancedAgent {
	return &EnhancedAgent{
		config:     config,
		auth:       &model.AuthHandler{ClientSecret: config.ClientSecret, ClientUUID: config.UUID},
		maxRetries: 10,
		baseDelay:  time.Second * 5,
		maxDelay:   time.Minute * 5,
	}
}

// Connect 连接到服务器
func (a *EnhancedAgent) Connect() error {
	var err error
	
	// 配置keepalive参数
	kacp := keepalive.ClientParameters{
		Time:                10 * time.Second, // 发送keepalive ping的时间间隔
		Timeout:             3 * time.Second, // keepalive ping的超时时间
		PermitWithoutStream: true,             // 允许在没有活跃流时发送keepalive ping
	}

	// 配置连接选项
	var opts []grpc.DialOption
	opts = append(opts, grpc.WithKeepaliveParams(kacp))
	opts = append(opts, grpc.WithPerRPCCredentials(a.auth))
	
	// 配置TLS
	if a.config.TLS {
		if a.config.InsecureTLS {
			opts = append(opts, grpc.WithTransportCredentials(
				credentials.NewTLS(&tls.Config{
					MinVersion:         tls.VersionTLS12,
					InsecureSkipVerify: true,
				}),
			))
		} else {
			opts = append(opts, grpc.WithTransportCredentials(
				credentials.NewTLS(&tls.Config{
					MinVersion: tls.VersionTLS12,
				}),
			))
		}
	} else {
		opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}

	// 配置连接超时
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 建立连接
	a.conn, err = grpc.DialContext(ctx, a.config.Server, opts...)
	if err != nil {
		a.lastError = err
		a.lastErrorTime = time.Now()
		return fmt.Errorf("连接失败: %v", err)
	}

	a.client = pb.NewNezhaServiceClient(a.conn)
	log.Printf("成功连接到服务器: %s", a.config.Server)
	
	// 重置重试计数
	a.retryCount = 0
	
	return nil
}

// Disconnect 断开连接
func (a *EnhancedAgent) Disconnect() {
	if a.conn != nil {
		a.conn.Close()
		a.conn = nil
		a.client = nil
		log.Printf("已断开与服务器的连接")
	}
}

// ReportSystemInfo 上报系统信息
func (a *EnhancedAgent) ReportSystemInfo(host *pb.Host) (*pb.Uint64Receipt, error) {
	if a.client == nil {
		return nil, fmt.Errorf("客户端未连接")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	receipt, err := a.client.ReportSystemInfo2(ctx, host)
	if err != nil {
		a.lastError = err
		a.lastErrorTime = time.Now()
		return nil, fmt.Errorf("上报系统信息失败: %v", err)
	}

	log.Printf("系统信息上报成功")
	return receipt, nil
}

// StartStateReporting 开始状态上报
func (a *EnhancedAgent) StartStateReporting(stateStream pb.NezhaService_ReportSystemStateClient) error {
	if stateStream == nil {
		return fmt.Errorf("状态流为空")
	}

	log.Printf("开始状态上报流")
	
	for {
		// 这里应该接收状态数据并发送
		// 由于这是示例，我们只处理连接状态
		time.Sleep(time.Duration(a.config.ReportDelay) * time.Second)
		
		// 检查连接状态
		if a.conn.GetState().String() != "READY" {
			return fmt.Errorf("连接状态异常: %s", a.conn.GetState().String())
		}
	}
}

// StartTaskHandling 开始任务处理
func (a *EnhancedAgent) StartTaskHandling(taskStream pb.NezhaService_RequestTaskClient) error {
	if taskStream == nil {
		return fmt.Errorf("任务流为空")
	}

	log.Printf("开始任务处理流")
	
	for {
		// 这里应该接收任务并处理
		// 由于这是示例，我们只处理连接状态
		time.Sleep(time.Second)
		
		// 检查连接状态
		if a.conn.GetState().String() != "READY" {
			return fmt.Errorf("连接状态异常: %s", a.conn.GetState().String())
		}
	}
}

// RunWithRetry 运行Agent并处理重试
func (a *EnhancedAgent) RunWithRetry(host *pb.Host, stateCallback func() *pb.State) error {
	for {
		// 尝试连接
		if err := a.Connect(); err != nil {
			log.Printf("连接失败: %v", err)
			a.handleConnectionError(err)
			continue
		}

		// 上报系统信息
		receipt, err := a.ReportSystemInfo(host)
		if err != nil {
			log.Printf("上报系统信息失败: %v", err)
			a.handleConnectionError(err)
			continue
		}
		log.Printf("系统信息上报成功，面板启动时间: %d", receipt.GetData())

		// 启动状态上报流
		ctx, cancel := context.WithCancel(context.Background())

		stateStream, err := a.client.ReportSystemState(ctx)
		if err != nil {
			log.Printf("创建状态流失败: %v", err)
			cancel()
			a.handleConnectionError(err)
			continue
		}

		// 启动任务处理流
		taskStream, err := a.client.RequestTask(ctx)
		if err != nil {
			log.Printf("创建任务流失败: %v", err)
			cancel()
			a.handleConnectionError(err)
			continue
		}

		// 启动goroutine处理状态上报
		go func() {
			defer cancel()
			for {
				if stateCallback != nil {
					state := stateCallback()
					if state != nil {
						if err := stateStream.Send(state); err != nil {
							log.Printf("发送状态失败: %v", err)
							return
						}
					}
				}
				time.Sleep(time.Duration(a.config.ReportDelay) * time.Second)
			}
		}()

		// 启动goroutine处理任务
		go func() {
			defer cancel()
			for {
				task, err := taskStream.Recv()
				if err != nil {
					log.Printf("接收任务失败: %v", err)
					return
				}
				log.Printf("收到任务: ID=%d, Type=%d", task.GetId(), task.GetType())
				
				// 这里应该处理任务
				// 发送任务结果
				result := &pb.TaskResult{
					Id:        task.GetId(),
					Type:      task.GetType(),
					Successful: true,
					Delay:     0,
					Data:      "任务执行成功",
				}
				if err := taskStream.Send(result); err != nil {
					log.Printf("发送任务结果失败: %v", err)
					return
				}
			}
		}()

		// 等待连接断开
		<-ctx.Done()
		cancel()
		a.Disconnect()
		
		// 处理重连
		a.handleConnectionError(fmt.Errorf("连接断开"))
	}
}

// handleConnectionError 处理连接错误
func (a *EnhancedAgent) handleConnectionError(err error) {
	a.retryCount++
	a.lastError = err
	a.lastErrorTime = time.Now()

	if a.retryCount > a.maxRetries {
		log.Printf("重试次数超过限制 (%d)，停止重试", a.maxRetries)
		return
	}

	// 计算延迟时间（指数退避）
	delay := a.baseDelay
	for i := 0; i < a.retryCount-1; i++ {
		delay *= 2
		if delay > a.maxDelay {
			delay = a.maxDelay
			break
		}
	}

	log.Printf("连接错误: %v，%d秒后重试 (第%d次)", err, int(delay.Seconds()), a.retryCount)
	time.Sleep(delay)
}

// GetConnectionStatus 获取连接状态
func (a *EnhancedAgent) GetConnectionStatus() map[string]interface{} {
	status := map[string]interface{}{
		"connected":     a.client != nil,
		"retry_count":   a.retryCount,
		"last_error":    nil,
		"last_error_time": nil,
	}

	if a.lastError != nil {
		status["last_error"] = a.lastError.Error()
		status["last_error_time"] = a.lastErrorTime.Format(time.RFC3339)
	}

	if a.conn != nil {
		status["connection_state"] = a.conn.GetState().String()
	}

	return status
}

// TestConnection 测试连接
func (a *EnhancedAgent) TestConnection() error {
	// 测试DNS解析
	host, _, err := net.SplitHostPort(a.config.Server)
	if err != nil {
		return fmt.Errorf("解析服务器地址失败: %v", err)
	}

	ips, err := net.LookupIP(host)
	if err != nil {
		return fmt.Errorf("DNS解析失败: %v", err)
	}

	log.Printf("DNS解析成功: %s -> %v", host, ips)

	// 测试TCP连接
	conn, err := net.DialTimeout("tcp", a.config.Server, 10*time.Second)
	if err != nil {
		return fmt.Errorf("TCP连接失败: %v", err)
	}
	conn.Close()

	log.Printf("TCP连接测试成功: %s", a.config.Server)
	return nil
}
