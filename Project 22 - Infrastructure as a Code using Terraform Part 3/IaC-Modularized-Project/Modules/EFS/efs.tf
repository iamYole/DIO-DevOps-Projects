# create key from key management system
/* resource "aws_kms_key" "ACS-kms" {
  description = "KMS key"
}

resource "aws_kms_key_policy" "ACS-kms-policy" {
  key_id = aws_kms_key.ACS-kms.id
  policy = jsonencode(
    {
      id = "kms-key-policy"
      Statement = [
        {
          Action = "kms:*"
          Effect = "Allow"
          #Principal = { "AWS" : "arn:aws:iam::${var.account_id}:user/aws-iamYole" }
          Principal = { AWS = "*" }
          Resource  = "*"
          Sid       = "Enable IAM User Permissions"
        },
      ]
      Version = "2012-10-17"
  })
} */

# create key alias
# resource "aws_kms_alias" "alias" {
#   name          = "alias/kms"
#   target_key_id = aws_kms_key.ACS-kms.key_id
# }

# create Elastic file system
resource "aws_efs_file_system" "ACS-efs" {
  //encrypted  = true
  //kms_key_id = aws_kms_key.ACS-kms.arn

  tags = merge(
    var.tags,
    {
      Name = "ACS-efs"
    },
  )
}

# set first mount target for the EFS 
resource "aws_efs_mount_target" "subnet-1" {
  file_system_id  = aws_efs_file_system.ACS-efs.id
  subnet_id       = var.private_subnets[2].id //aws_subnet.private[2].id
  security_groups = [var.datalayer-sg_id]
}

# set second mount target for the EFS 
resource "aws_efs_mount_target" "subnet-2" {
  file_system_id  = aws_efs_file_system.ACS-efs.id
  subnet_id       = var.private_subnets[3].id //aws_subnet.private[3].id
  security_groups = [var.datalayer-sg_id]
}

# create access point for wordpress
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.ACS-efs.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/wordpress"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }

  }

}


# create access point for tooling
resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.ACS-efs.id
  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {

    path = "/tooling"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }

  }
}

