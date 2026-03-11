# Handles upgrade from version 1 where archive was a separate submodule to version 2
moved {
  from = module.archive.random_string.archive
  to   = random_string.archive
}

moved {
  from = module.archive.google_storage_bucket.archive
  to   = google_storage_bucket.archive
}

moved {
  from = module.archive.google_storage_bucket_iam_member.archive_write
  to   = google_storage_bucket_iam_member.archive_write
}

moved {
  from = module.archive.google_storage_bucket_iam_member.archive_delete
  to   = google_storage_bucket_iam_member.archive_delete
}

moved {
  from = module.archive.google_storage_bucket_iam_member.archive_reader
  to   = google_storage_bucket_iam_member.archive_reader
}
