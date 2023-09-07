
output "resource_ids" {
  value = {
    archive_role_write  = google_project_iam_custom_role.archive_object_write.id,
    archive_role_delete = google_project_iam_custom_role.archive_object_delete.id
  }
}
