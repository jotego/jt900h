package main

import (
	"fmt"
	"os"
	"strings"
	"bufio"
	"strconv"
)

var verbose bool

func find_first( finame string ) []byte {
	fin, err_fin := os.Open(finame+".lst")
	if err_fin != nil {
		fmt.Println("Cannot open list file ", finame)
		os.Exit(1)
	}
	defer fin.Close()
	scanner := bufio.NewScanner(fin)
	for scanner.Scan() {
		split := strings.SplitN(scanner.Text(),"  ",3)
		if len(split)>2 {
			val := strings.TrimSpace(split[1])
			if split[0]=="00000000" && len(val)>0 {
				lenb := len(val)>>1
				if verbose {
					fmt.Printf("->%s<- bytes = %d\n",val,lenb)
				}
				bytearr := make( []byte, lenb )
				for k:=0;k<lenb;k=k+1 {
					i,_ := strconv.ParseInt(val[0:2],16,32)
					if verbose {
						fmt.Printf("%s -> %02X\n",val[0:2],i)
					}
					val = val[2:]
					bytearr[k] = byte(i)
				}
				if verbose {
					fmt.Println()
				}
				return bytearr
			}
		}
	}
	return nil
}

func main() {
	verbose = false
	fi_name := ""
	if len(os.Args) == 2 {
		fi_name = os.Args[1]
		if k := strings.LastIndex(fi_name,"."); k!= -1 {
			fi_name = fi_name[0:k]
		}
	} else {
		fmt.Println("Error: expecting only the filename as argument")
		os.Exit(1)
	}
	first := find_first( fi_name )
	if first == nil {
		fmt.Println("Cannot identify the first instruction. Did you use a label in it?")
		os.Exit(1)
	}
	// Find the first instruction
	fin, err_fin := os.Open(fi_name+".abs")
	defer fin.Close()
	if err_fin != nil {
		fmt.Println("Cannot open ", fi_name)
		os.Exit(1)
	}
	buf := make([]byte, 0x10000)
	n, _ := fin.Read(buf)
	if n != 0 {
		k := 0
		matched := 0
		offset :=0
		for k = 0; k < n; k++ {
			if buf[k]==first[matched] {
				matched=matched+1
				if matched >= len(first) {
					offset = k-len(first)+1
					break
				}
			} else {
				// if verbose {
				// 	fmt.Printf("%02X <> %02X\n",buf[k],first[matched])
				// }
				matched=0
			}
		}
		if offset == 0 {
			fmt.Printf("Cannot find the first instruction in %s.abs\n",fi_name)
			os.Exit(1)
		}
		fo_name := fi_name + ".bin"
		fout, err_f := os.Create(fo_name)
		defer fout.Close()
		if err_f != nil {
			fmt.Println("Error creating the output file ", fo_name, " ", err_f)
			os.Exit(1)
		}
		fout.Write(buf[offset:n-1])
	} else {
        fmt.Println("Empty file ",fi_name)
    }
}
