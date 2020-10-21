local helper = require("kivi/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("kivi file source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute child action", function()
    helper.new_file("file")

    command("Kivi")
    command("normal! G")
    command("KiviDo child")

    assert.file_name("file")
  end)

  it("can execute parent action", function()
    helper.new_file("file")
    helper.new_directory("dir")
    helper.cd("dir")

    command("Kivi")
    command("KiviDo parent")

    assert.exists_pattern("file")
    assert.current_line("dir/")
  end)

end)
