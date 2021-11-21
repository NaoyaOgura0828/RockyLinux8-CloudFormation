# RockyLinux8-CloudFormation

`RockyLinux8-CloudFormation`は`AWS CloudFormation`を利用し、`Rocky Linux 8 (Official)`の実行環境を構築する。
<br>
また、本書は日本語デスクトップ環境のセットアップ手順を含む。


# Requirement
作成時点では以下の環境にローカル環境よりSSH接続で実行検証済
- インスタンス: AWS EC2
- OS: Amazon Linux 2

**`Windows`環境では`.sh`が実行出来ないので注意**

<br>

2021-11-21現在の適用`Rocky Linux 8 (Official) AMI ID`
- ami-01c6603b0b5d545ec

<br>


# Installation

1. AWSへアクセスし、CloudFormation実行用IAMユーザーを作成する。
    <br>
    ユーザーポリシーは下記を推奨する。
    <br>
    但しポリシー要件によってAdmin権限が許可されない場合は構築リソースによって最小権限とする事。

```text
# ユーザーポリシー
arn:aws:iam::aws:policy/AdministratorAccess
```

<br>

2. `{作成したユーザー}`を選択し`認証情報`タブへ移動`アクセスキーの作成`を行う。
    <br>
    credentialの記載された`.csv`ファイルをダウンロードする。

<br>

3. `.aws`を作成する。

```Bash
$ aws configure
```

**上記を実行すると`AWS Access Key ID`等の入力を求められるが、次のステップでファイルを編集するので何も入力せずに進む。**

<br>

4. `.csv`内に記載されている`Access key ID`及び`Secret access key`を`\.aws\credentials`内に転記する。

```text
# {環境名}は{dev|stg|prod}から任意に選択する。
[RockyLinux8-{環境名}]
aws_access_key_id = {Access key ID}
aws_secret_access_key = {Secret access key}
region = ap-northeast-1
```

<br>

5. `Bash`で各`.sh`に権限を付与する。

```Bash
$ chmod +x ${ファイル名}
```

<br>


# Usage
1. SSH接続用のキーペアを作成する。
    <br>
    `AWSコンソール`へアクセスし、`\EC2\キーペア\キーペアを作成`から作成。
    <br>
    キーペアのタイプは`RSA`を
    <br>
    プライベートキーファイル形式は`.pem`形式を選択する事。

<br>

2. キーペア名を登録する。
    <br>
    `\RockyLinux8\ami-build`及び`RockyLinux8\ec2`内の`{環境名}-parameters.json`へキーペア名を設定する。

```json
        {
            "ParameterKey": "KeyName",
            "ParameterValue": "{任意のキーペア名}"
        },
```

<br>

3. 展開したいNetworkを設定する。
    <br>
    `\RockyLinux8\network\{環境名}-parameters.json`に任意の`CIDR`を設定する。

```json
{
    "Parameters": [
        {
            "ParameterKey": "SystemName",
            "ParameterValue": "RockyLinux8"
        },
        {
            "ParameterKey": "EnvType",
            "ParameterValue": "dev"
        },
        {
            "ParameterKey": "VPCCidrBlock",
            "ParameterValue": "200.0.0.0/16"
        },
        {
            "ParameterKey": "PublicSubnetCidrBlock",
            "ParameterValue": "200.0.1.0/24"
        }
    ]
}
```

<br>

4. 構築リソースを設定する。
    <br>
    `create_stacks.sh`内の**`# 最初に実行する`のみ**をコメントアウト解除する。

```Bash
#####################################
# 最初に実行する
#####################################
create_stack iam
create_stack network
create_stack sg
create_stack ami-build
aws imagebuilder start-image-pipeline-execution --image-pipeline-arn $(aws imagebuilder list-image-pipelines --query 'imagePipelineList[].arn' --output text --profile ${SYSTEM_NAME}-${ENV_TYPE}) --profile ${SYSTEM_NAME}-${ENV_TYPE}
```

<br>

5. リソースを構築する。
<br>
`Bash`で以下のコマンドを実行する。

```Bash
$ ./create_stack.sh ${環境名}
```

<br>

6. `AMI ID`を設定する。
    <br>
    `AWSコンソール`へアクセスし、`\EC2\AMI\RockyLinux8-{環境名}-ec2-ami`の`AMI ID`をコピーする。
    <br>
    `\RockyLinux8\ec2\{環境名}-parameters.json`内の`AMIID`へペーストする。
    <br>
    **`ImageBuilder`によって`AMI`は自動で作成されるが時間がかかるので注意を要する。**

```json
        {
            "ParameterKey": "AMIID",
            "ParameterValue": "{ここにAMI IDを貼り付ける}"
        },
```

<br>

7. EC2構築を設定する。
    <br>
    `create_stacks.sh`内の**`create_stack ec2`のみ**をコメントアウト解除する。

```Bash
#####################################
# 最初に実行する
#####################################
# create_stack iam
# create_stack network
# create_stack sg
# create_stack ami-build
# aws imagebuilder start-image-pipeline-execution --image-pipeline-arn $(aws imagebuilder list-image-pipelines --query 'imagePipelineList[].arn' --output text --profile ${SYSTEM_NAME}-${ENV_TYPE}) --profile ${SYSTEM_NAME}-${ENV_TYPE}

#####################################
# /RockyLinux8/ec2/{EnvType}-parameters.json
# "AMIID" へ作成されたAMI IDを入力後実行する
#####################################
create_stack ec2
```

<br>

8. EC2を構築する。
    <br>
    `Bash`で以下のコマンドを実行する。

```Bash
$ ./create_stack.sh ${環境名}
```

<br>

9. EC2インスタンスへSSH接続後、Bashで以下の設定を行う。

```Bash
# 日本語設定を適用
$ sodo localectl set-locale LANG=ja_JP.utf8

# RDP ポートの許可
$ sudo firewall-cmd --permanent --add-port=3389/tcp
# firewalld 再起動
$ sudo systemctl restart firewalld.service
```

<br>

10. Bashでユーザーアカウントを作成する。

```Bash
# ユーザー追加
$ sudo adduser ${user_name}

# パスワード設定
$ sudo passwd ${user_name}
$ ${password}
$ ${password}

# ユーザーを管理者グループへ追加
$ sudo usermod -G adm ${user_name}

# ユーザーをsudoersへ追加
$ sudo visudo
# 末尾へユーザー名を追記する
rocky   ALL=(ALL)       NOPASSWD: ALL
{user_name}   ALL=(ALL)       NOPASSWD: ALL
```

<br>

11. 作成したユーザーアカウントへのSSH接続設定を行う。

```Bash
# ユーザー切り替え
$ su - ${user_name}
$ ${password}

# .sshディレクトリ作成
$ mkdir .ssh
# .sshに対して${new_user}の全権許可(他ユーザーは許可しない)
$ chmod 700 .ssh
# .ssh/authorized_keys 作成
$ touch .ssh/authorized_keys
# authorized_keysに対して${new_user}の読み書き許可(他ユーザーは許可しない)
$ chmod 600 .ssh/authorized_keys

# 接続中インスタンスのパブリックキーを取得し.ssh/authorized_keysへ書き込む
$ TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
&& curl -H "X-aws-ec2-metadata-token: $TOKEN" –v http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > .ssh/authorized_keys
```

<br>

12. 以上で作成したユーザーアカウントへ`SSH`接続及び`RDP`接続が可能となる。

<br>


# Note
- 現在対応している環境名は `dev`(開発用), `stg`(検証用), `prod`(本番用) のみである。
- `create_change_sets.sh` (更新用) についてはコマンド実行後、変更セットの実行が必要である。
    <br>
    参考URL:
    <br>
    https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets-execute.html
- EC2の構成は`\RockyLinux8\ec2\{環境名}-parameters.json`内で任意に行うことが出来る。

<br>

### 推奨される拡張機能
- Dash to Panel

<br>

### 推奨されるデスクトップログイン後GUI設定
- Tweaks 設定

<br>


# Author
- 作成者 : NaoyaOgura
