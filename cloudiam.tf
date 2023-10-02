resource "google_project" "project" {
  name            = var.project
  billing_account = var.billing_account
  project_id = var.project_id
}

resource "google_access_context_manager_access_level" "test-access" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.access-policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.access-policy.name}/accessLevels/chromeos_no_lock"
  title  = "chrome_os_no_lock"
  basic {
    conditions {
      device_policy {
        require_screen_lock = true
        os_constraints {
          os_type = var.os-type
        }
      }
      regions = [
        "CH",
        "IT",
        "US",
      ]
    }
  }
}

resource "google_access_context_manager_access_policy" "access-policy" {
  parent = "organizations/${google_project.project}"
  title  = "my policy"
}

resource "google_iam_access_boundary_policy" "example" {
  parent   = urlencode("cloudresourcemanager.googleapis.com/projects/${google_project.project.project_id}")
  name     = "my-ab-policy"
  display_name = "My AB policy"
  rules {
    description = "AB rule"
    access_boundary_rule {
      available_resource = "*"
      available_permissions = ["*"]
      availability_condition {
        title = "Access level expr"
        expression = "request.matchAccessLevels('${google_project.project}', ['${google_access_context_manager_access_level.test-access.name}'])"
      }
    }
  }
}