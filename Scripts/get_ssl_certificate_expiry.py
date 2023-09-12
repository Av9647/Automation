
import datetime
import socket
import ssl
import http.client

def get_num_days_before_expired(hostname: str, port: str = '443') -> int:
    context = ssl.create_default_context()
    with socket.create_connection((hostname, port)) as sock:
        with context.wrap_socket(sock, server_hostname=hostname) as ssock:
            ssl_info = ssock.getpeercert()
            expiry_date = datetime.datetime.strptime(ssl_info['notAfter'], '%b %d %H:%M:%S %Y %Z')
            delta = expiry_date - datetime.datetime.utcnow()
            print(f'{hostname} expires in {delta.days} day(s)')
            return delta.days


if __name__ == '__main__':
    get_num_days_before_expired('g7w11235g.inc.hpicorp.net', '8000')
