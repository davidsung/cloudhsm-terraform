# Use CloudHSM to import p12 rsa 2048bit

```
terraform init
terraform plan
terraform apply
```

## CloudHSM initialization
```
terraform output cloudhsm_cluster_csr > cluster.csr
openssl genrsa -aes256 -out customerCA.key 2048
openssl req -new -x509 -days 3652 -keyout customerCA.key -subj '/O=Octagon Ltd./C=HK' -out customerCA.crt
openssl x509 -req -days 3652 -in cluster.csr \
                              -CA customerCA.crt \
                              -CAkey customerCA.key \
                              -CAcreateserial \
                              -out CustomerHsmCertificate.crt
aws cloudhsmv2 initialize-cluster --cluster-id $(ir terraform output cloudhsm_cluster_id) \
                                    --signed-cert file://CustomerHsmCertificate.crt \
                                    --trust-anchor file://customerCA.crt
```

```
{
    "State": "INITIALIZE_IN_PROGRESS",
    "StateMessage": "Cluster is initializing. State will change to INITIALIZED upon completion."
}
```

# Install AWS CloudHSM Client
Connect to your client instance
```
wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/EL6/cloudhsm-client-latest.el6.x86_64.rpm
sudo yum install -y ./cloudhsm-client-latest.el6.x86_64.rpm
```

Copy self signed CA certificate to the client instance
```
scp customerCA.crt ec2-user@$(ir terraform output hsm_client_hostname):~/
sudo mv customerCA.crt /opt/cloudhsm/etc/
```

Configure HSM IP address
```
sudo /opt/cloudhsm/bin/configure -a <IP address>
```

# Activate the cluster
```
/opt/cloudhsm/bin/cloudhsm_mgmt_util /opt/cloudhsm/etc/cloudhsm_mgmt_util.cfg
```

```
aws-cloudhsm>enable_e2e

E2E enabled on server 0(server1)
```

```
aws-cloudhsm>listUsers
Users on server 0(server1):
Number of users found:2

    User Id             User Type       User Name                          MofnPubKey    LoginFailureCnt         2FA
         1              PRECO           admin                                    NO               0               NO
         2              AU              app_user                                 NO               0               NO
```

```
aws-cloudhsm>loginHSM PRECO admin password
```

```
aws-cloudhsm>changePswd PRECO admin <NewPassword>
```

```
aws-cloudhsm>listUsers
```

```
aws-cloudhsm>quit
```

## Create CryptoUser
```
loginHSM CO admin <Password>
```

```
createUser CU bob password
```

## Generate P12 certificate with RSA 2048bit key length
```
openssl req -x509 -newkey rsa:2048 -keyout myKey.pem -out cert.pem -days 365 -nodes -subj "/C=HK/O=Octagon, Inc./CN=bob@octagon.com"
openssl pkcs12 -export -out myKey.p12 -inkey myKey.pem -in cert.pem
```

## Extract Private Key
```
openssl pkcs12 -in myKey.p12 -nocerts -nodes -out export_myKey.key
```

## Extract Public Certifciate
```
openssl x509 -pubkey -in cert.pem -noout > export_myKey.crt
```

## Login HSM using key_mgmt_util
```
sudo service cloudhsm-client start
/opt/cloudhsm/bin/key_mgmt_util
loginHSM -u CU -s [crypto_user_name] -p [password]
```

## Generate Session Symmetric Enc Key 
```
genSymKey -t 31 -s 16 -sess -l wrapping_key_for_import
	Cfm3GenerateSymmetricKey returned: 0x00 : HSM Return: SUCCESS

	Symmetric Key Created.  Key Handle: 6

	Cluster Status:
	Node id 0 status: 0x00000000 : HSM Return: SUCCESS
```

## Import Private Key
```
importPrivateKey -f export_myKey.key -l my_private_key -w <wrapping_key_handle>
BER encoded key length is 1217

	Cfm3ImportWrapKey returned: 0x00 : HSM Return: SUCCESS

	Cfm3CreateUnwrapTemplate2 returned: 0x00 : HSM Return: SUCCESS

	Cfm3ImportUnWrapKey: 0x00 : HSM Return: SUCCESS

	Private Key Imported.  Key Handle: 9

	Cluster Status:
	Node id 0 status: 0x00000000 : HSM Return: SUCCESS
```

## Import Public Key
```
importPubKey -l my_public_key -f export_myKey.crt
	Cfm3CreatePublicKey returned: 0x00 : HSM Return: SUCCESS

Public Key Handle: 7

	Cluster Status:
	Node id 0 status: 0x00000000 : HSM Return: SUCCESS
```

## Sign using Private Key
```
sign -f [] -k [private_key_handle] -m 1 -out [output_file]

	Signature creation successful

	signature is written to file message.txt.signed

	Cfm3Sign: sign returned: 0x00 : HSM Return: SUCCESS
```

## Verify using Public Key
```
verify -f message.txt -s message.txt.signed -k [public_key_handle] -m 1

	Signature verifition successful

	Cfm3Verify returned: 0x00 : HSM Return: SUCCESS
```

## Logout and exit
```
logoutHSM
exit
```