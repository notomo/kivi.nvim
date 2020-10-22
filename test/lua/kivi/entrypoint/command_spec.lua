local helper = require("kivi/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("kivi", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui", function()
    command("Kivi")

    assert.filetype("kivi")
  end)

  it("can reload ui", function()
    helper.new_file("file")

    command("Kivi")
    command("edit!")

    assert.exists_pattern("file")
  end)

  it("can remember path history", function()
    helper.new_directory("dir")
    helper.new_file("dir/file1")
    helper.new_file("dir/file2")
    helper.cd("dir")

    command("Kivi")
    helper.search("file2")

    command("KiviDo parent")

    command("KiviDo child")

    assert.current_line("file2")
  end)

end)
