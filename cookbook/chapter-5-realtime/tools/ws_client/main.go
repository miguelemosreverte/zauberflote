package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	url := flag.String("url", "", "websocket url")
	msg := flag.String("msg", "ping", "message")
	flag.Parse()
	if *url == "" {
		fmt.Println("missing -url")
		os.Exit(2)
	}

	dialer := websocket.Dialer{HandshakeTimeout: 3 * time.Second}
	conn, _, err := dialer.Dial(*url, nil)
	if err != nil {
		fmt.Println("dial error:", err)
		os.Exit(1)
	}
	defer conn.Close()

	if err := conn.WriteMessage(websocket.TextMessage, []byte(*msg)); err != nil {
		fmt.Println("write error:", err)
		os.Exit(1)
	}

	_, resp, err := conn.ReadMessage()
	if err != nil {
		fmt.Println("read error:", err)
		os.Exit(1)
	}

	fmt.Println(string(resp))
}
