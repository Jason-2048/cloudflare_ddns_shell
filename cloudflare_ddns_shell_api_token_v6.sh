#!/bin/bash

## 全局变量

# API Token
api_token="example"
# 区域 ID (Zone ID)
zone_id="example"
# 目标记录 ID
record_id="example"



## IPv6

# 目标记录
record_name="example.com"

record_type_v6="AAAA"

# 利用 CloudFlare 服务检测外网 IPv6
record_ip_v6=$(curl -s ipv6.icanhazip.com)

# 向 CloudFlare 更新目标域名的解析结果
update_record_response_v6=$(curl -s --request PUT \
                                 -L https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id_v6 \
                                 -H 'Content-Type: application/json' \
                                 -H "Authorization: Bearer $api_token" \
                                 --data "{\"content\": \"$record_ip_v6\", \"name\": \"$record_name_v6\", \"type\": \"$record_type_v6\"}")

# 利用返回值判断是否更新成功
update_record_v6=$(echo "$update_record_response_v6" | jq '.success')

sleep 5

# 主动向 CloudFlare 请求目标域名的解析结果并记录
record_ip_check_response_v6=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type_v6&name=$record_name_v6" \
                                   -H "Authorization: Bearer $api_token" \
                                   -H "Content-Type: application/json")

record_ip_check_v6=$(echo "$record_ip_check_response_v6" | jq -r '.result[0].content')



## 循环部分

# 最大尝试次数
max_retries=5

retry_count=0

while [ $retry_count -lt $max_retries ]; do
  if [ "$record_ip_v6" = "$record_ip_check_v6" ] && [ "$update_record_v6" = "true" ]; then
    break
  else
    retry_count=$((retry_count + 1))
    # 记录错误时间和对应次数
    echo "$(date +"%Y-%m-%d %H:%M:%S") 错误第 $retry_count 次" > /var/log/cloudflare_ddns_shell_api_token_v6_error.log
    echo "$update_record_response" > /var/log/cloudflare_ddns_shell_api_token_v6_error.log
    echo "$record_ip_check_response" > /var/log/cloudflare_ddns_shell_api_token_v6_error.log
    exec "$0" "$@"
  fi
done



## 邮件SMTP部分

# 邮件SMTP变量

# SMTP 地址
smtp_server="smtp.example.com"
# SMTP 端口
smtp_port="465"
# SMTP 账号
smtp_user="example@example.com"
# SMTP 密码
smtp_password="example"
# SMTP 发件人邮箱
sender_email="example@example.com"
# SMTP 收件人邮箱
recipient_email="example@example.com"

# 达到循环上限后发送邮件
if [ $retry_count -eq $max_retries ]; then
  curl --url "smtps://$smtp_server:$smtp_port" \
       --ssl-reqd \
       --mail-from "$sender_email" \
       --mail-rcpt "$recipient_email" \
       --user "$smtp_user:$smtp_password" \
       --upload-file - <<EOF
From: $sender_email
To: $recipient_email
Subject: [server] cloudflare_ddns_shell_api_token_v6 脚本错误次数已达到 $max_retries 次

EOF
fi
