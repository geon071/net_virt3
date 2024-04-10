resource "yandex_iam_service_account" "s3-bucket" {
    name      = "acc-bucket"
}

resource "yandex_resourcemanager_folder_iam_member" "s3-bucket-editor" {
  folder_id = "${var.folder_id}"
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.s3-bucket.id}"
}

resource "yandex_iam_service_account_static_access_key" "s3-bucket-key" {
  service_account_id = yandex_iam_service_account.s3-bucket.id
  description        = "access key for s3"
}

resource "yandex_storage_bucket" "static-pic" {
    access_key = yandex_iam_service_account_static_access_key.s3-bucket-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.s3-bucket-key.secret_key
    bucket = "static-pic"
    acl    = "public-read"
}

resource "yandex_storage_object" "pic" {
  access_key = yandex_iam_service_account_static_access_key.s3-bucket-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3-bucket-key.secret_key
  bucket     = yandex_storage_bucket.static-pic.bucket
  key        = "pic"
  source     = "./pic_s3/winBlack.jpg"
}