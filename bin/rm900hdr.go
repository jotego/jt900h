package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	fi_name := ""
	if len(os.Args) == 2 {
		fi_name = os.Args[1]
	} else {
		fmt.Println("Error: expecting only the filename as argument")
		os.Exit(1)
	}
	fin, err_fin := os.Open(fi_name)
	if err_fin != nil {
		fmt.Println("Cannot open ", fi_name)
		os.Exit(1)
	}
	buf := make([]byte, 0x10000)
	n, _ := fin.Read(buf)
	if n != 0 {
		k := 0
		matched := 0
		for k = 0; k < n; k++ {
			if fnd_ed && buf[k] == 0x37 {
				k++
				break
			} else {
				fnd_ed = buf[k] == 0xed
			}
		}
		fo_name := strings.TrimSuffix(fi_name, ".abs") + ".bin"
		fout, err_f := os.Create(fo_name)
		if err_f != nil {
			fmt.Println("Error creating the output file ", fo_name, " ", err_f)
			os.Exit(1)
		}
		fout.Write(buf[k:n-1])
	} else {
        fmt.Println("Empty file ",fi_name)
    }
}
