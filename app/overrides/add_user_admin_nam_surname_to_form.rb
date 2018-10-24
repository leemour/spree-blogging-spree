Deface::Override.new(
  virtual_path: "spree/admin/users/_form",
  name: "add_admin_user_name_and_surname",
  insert_bottom: "[data-hook='admin_user_form_fields']",
  partial: "spree/admin/users/add_user_name_fields",
  disabled: false
)
