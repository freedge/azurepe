package main

import (
	"fmt"
	"net"
	"os"
	"time"
)

var quit = make(chan struct{})

func main() {
	addr, err := net.ResolveTCPAddr("tcp", os.Args[1]) // :8080
	if err != nil {
		panic(err)
	}
	var d time.Duration
	if len(os.Args) >= 3 {
		d, err = time.ParseDuration(os.Args[2]) // 2h
		if err != nil {
			panic(err)
		}
	}

	listener, err := net.ListenTCP("tcp", addr)
	if err != nil {
		panic(err)
	}

	for {
		conn, err := listener.AcceptTCP()
		if err != nil {
			fmt.Println("err:", err)
			continue
		}

		if len(os.Args) >= 3 {
			conn.SetKeepAlive(true)
			conn.SetKeepAlivePeriod(d)
		}

		go func(conn net.Conn) {
			defer conn.Close()
			// actually send 1 packet
			conn.Write([]byte("ping"))
			// just hang there
			<-quit
		}(conn)
	}
}
