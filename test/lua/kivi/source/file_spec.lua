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

  it("moves current directory", function()
    helper.new_directory("dir")

    command("Kivi")
    helper.search("dir")
    command("KiviDo child")

    assert.current_dir("dir")
  end)

  it("place cursor to the node that has source buffer's file path", function()
    helper.new_file("file1")
    helper.new_file("file2")
    helper.new_file("file3")

    command("edit file3")

    command("Kivi")

    assert.current_line("file3")
  end)

  it("raise error if path does not exist", function()
    assert.error_message("does not exist: invalid_file_path", function()
      command("Kivi --path=invalid_file_path")
    end)
  end)

  it("can delete file", function()
    helper.set_inputs("Y")

    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo delete")

    assert.no.exists_pattern("file1")
    assert.exists_pattern("file2")
  end)

  it("can delete directory", function()
    helper.set_inputs("Y")

    helper.new_directory("dir1")
    helper.new_directory("dir2")

    command("Kivi")
    helper.search("dir1")
    command("KiviDo delete")

    assert.no.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can execute vsplit_open action", function()
    helper.new_file("file1")

    command("Kivi")
    command("KiviDo vsplit_open")

    assert.window_count(2)
  end)

end)
