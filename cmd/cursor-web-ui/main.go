package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/yuaotian/go-cursor-help/internal/web"
)

var (
	port    = flag.String("port", "8080", "port to run the web server on")
	version = "dev"
)

func main() {
	flag.Parse()
	
	// Set up logging
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	
	fmt.Printf("🚀 Cursor Helper Web UI v%s\n", version)
	fmt.Printf("🌐 Starting web server on port %s\n", *port)
	fmt.Printf("📱 Open your browser and go to: http://localhost:%s\n", *port)
	fmt.Println("Press Ctrl+C to stop the server")
	
	// Create and start web server
	server := web.NewServer()
	if err := server.Start(*port); err != nil {
		log.Printf("❌ Failed to start server: %v", err)
		os.Exit(1)
	}
}