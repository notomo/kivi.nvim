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

  it("can execute action", function()
    helper.new_file("file")

    command("Kivi")
    command("normal! G")
    command("KiviDo")

    assert.file_name("file")
  end)

end)
