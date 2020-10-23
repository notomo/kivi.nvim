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

  it("opens with the cursor on the second line", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")

    assert.current_line("file1")
  end)

  it("can execute yank action", function()
    helper.new_file("file")

    command("Kivi")
    command("KiviDo yank")

    assert.register_value("+", helper.test_data_dir .. "file")
  end)

end)
