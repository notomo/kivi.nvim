local helper = require("kivi/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("kivi", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui", function()
    command("Kivi")

    assert.filetype("kivi-file")
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

  it("can execute back action", function()
    helper.new_directory("dir1")
    helper.new_directory("dir1/dir2")

    command("Kivi --path=dir1/dir2")
    command("KiviDo parent")
    command("KiviDo parent")
    command("KiviDo back")

    assert.current_dir("dir1")

    command("KiviDo back")
    assert.current_dir("dir1/dir2")

    command("KiviDo back")
    assert.current_dir("dir1/dir2")
  end)

  it("can select nodes and execute action", function()
    helper.new_file("file1")
    helper.new_file("file2")
    helper.new_file("file3")

    command("Kivi")
    helper.search("file2")
    command("KiviDo toggle_selection")
    helper.search("file3")
    command("KiviDo toggle_selection")
    command("KiviDo tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo toggle_selection")
    command("KiviDo tab_open")

    command("tabprevious")
    helper.search("file2")
    command("KiviDo tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by toggle_selection action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo toggle_selection")
    command("KiviDo toggle_selection")
    helper.search("file2")
    command("KiviDo tab_open")

    assert.tab_count(2)
    assert.file_name("file2")
  end)

  it("does not move the cursor on opening the same path", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file2")
    command("Kivi")

    assert.current_line("file2")
  end)

  it("can toggle tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    command("Kivi")

    helper.search("dir")
    command("KiviDo toggle_tree")

    assert.exists_pattern("  file")
    assert.current_line("dir/")

    command("KiviDo toggle_tree")

    assert.current_line("dir/")
    assert.no.exists_pattern("  file")
  end)

  it("can reload renamer", function()
    helper.new_file("file")

    command("Kivi")

    helper.search("file")
    command("KiviDo rename")

    command("edit!")

    assert.exists_pattern("file")
  end)

  it("shows already exists error on creator", function()
    helper.new_file("file")

    command("Kivi")
    command("KiviDo create")

    vim.fn.setline(1, "file")
    command("w")

    assert.exists_message("already exists: .*/file")
  end)

  it("shows already exists error on renamer", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")

    helper.search("file1")
    command("KiviDo rename")

    command("s/file1/file2/")
    command("w")

    assert.exists_message("already exists: .*/file2")
  end)

  it("shows `can't open` error", function()
    assert.error_message("can't open /root/", function()
      command("Kivi --path=/root")
    end)
  end)

end)
