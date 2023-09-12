
import subprocess

def get_nodetype():
    try:
        hostname = subprocess.check_output(["powershell", "hostname"], shell=True)
        node = subprocess.check_output(["powershell", """(Get-ClusterGroup | Select -ExpandProperty "OwnerNode").Name[0]"""], shell=True)
        if node == hostname:
            return "Active"
        else:
            return "Passive"
    except Exception as ex:
        print (str(ex))
        return None

nodetype = get_nodetype()
