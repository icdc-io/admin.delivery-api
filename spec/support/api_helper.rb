module ApiHelper

  def header_with_admin
    {
      :Authorization =>  "Bearer " + JWT.encode({
        "external": {
          "accounts": {
            "test": {
              "roles": ["admin"]
            },
          }
        },
        "groups": ["test.admin"],
        "user_id": "test_admin@test.com",
        "name": "Test Admin"
      }, nil)
    }
  end
end