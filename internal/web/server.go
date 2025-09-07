package web

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/sirupsen/logrus"

	"github.com/yuaotian/go-cursor-help/internal/config"
	"github.com/yuaotian/go-cursor-help/internal/process"
	"github.com/yuaotian/go-cursor-help/pkg/idgen"
)

// Server represents the web server instance
type Server struct {
	mux            *http.ServeMux
	configManager  *config.Manager
	processManager *process.Manager
	generator      *idgen.Generator
	logger         *logrus.Logger
}

// NewServer creates a new web server instance
func NewServer() *Server {
	// Set up logger
	logger := logrus.New()
	logger.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:          true,
		DisableLevelTruncation: true,
		PadLevelText:           true,
	})
	logger.SetLevel(logrus.InfoLevel)

	// Initialize components
	currentUser := getCurrentUser()
	configManager, err := config.NewManager(currentUser)
	if err != nil {
		logger.Fatalf("Failed to initialize config manager: %v", err)
	}

	processManager := process.NewManager(nil, logger)
	generator := idgen.NewGenerator()

	// Create HTTP mux
	mux := http.NewServeMux()

	server := &Server{
		mux:            mux,
		configManager:  configManager,
		processManager: processManager,
		generator:      generator,
		logger:         logger,
	}

	server.setupRoutes()
	return server
}

// Start starts the web server
func (s *Server) Start(port string) error {
	server := &http.Server{
		Addr:    ":" + port,
		Handler: s.mux,
	}

	// Start server in a goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	s.logger.Println("Shutting down server...")

	// Give outstanding requests a deadline for completion
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		s.logger.Fatal("Server forced to shutdown:", err)
	}

	s.logger.Println("Server exited")
	return nil
}