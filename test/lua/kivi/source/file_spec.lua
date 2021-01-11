local helper = require("kivi/lib/testlib/helper")
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
    assert.exists_pattern("dir/")
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
    helper.set_inputs("y")

    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo delete")

    assert.no.exists_pattern("file1")
    assert.exists_pattern("file2")
  end)

  it("can delete directory", function()
    helper.set_inputs("y")

    helper.new_directory("dir1")
    helper.new_directory("dir2")

    command("Kivi")
    helper.search("dir1")
    command("KiviDo delete")

    assert.no.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can cancel deleting", function()
    helper.set_inputs("n")

    helper.new_file("file")

    command("Kivi")
    helper.search("file")
    command("KiviDo delete")

    assert.exists_pattern("file")
    assert.exists_message("canceled.")
  end)

  it("saves tree on deleting", function()
    helper.set_inputs("y")

    helper.new_file("file")
    helper.new_directory("dir")
    helper.new_file("dir/in_dir")

    command("Kivi")

    helper.search("dir")
    command("KiviDo toggle_tree")

    helper.search("file")
    command("KiviDo delete")

    assert.no.exists_pattern("file")
    assert.exists_pattern("  in_dir")
  end)

  it("saves tree on pasting", function()
    helper.new_file("file")
    helper.new_directory("dir")
    helper.new_file("dir/in_dir")

    command("Kivi")

    helper.search("dir")
    command("KiviDo toggle_tree")

    helper.search("in_dir")
    command("KiviDo copy")

    helper.search("file")
    command("KiviDo paste")

    assert.exists_pattern("^in_dir$")
    assert.exists_pattern("  in_dir$")
  end)

  it("can execute vsplit_open action", function()
    helper.new_file("file1")

    command("Kivi")
    command("KiviDo vsplit_open")

    assert.window_count(2)
  end)

  it("can copy file and paste", function()
    helper.new_file("file")
    helper.new_directory("dir")

    command("Kivi")

    helper.search("file")
    command("KiviDo copy")
    assert.exists_message("copied: .*file")

    helper.search("dir")
    command("KiviDo child")

    command("KiviDo paste")

    assert.exists_pattern("file")

    command("KiviDo parent")
    assert.exists_pattern("file")
  end)

  it("can copy directory and paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file")
    helper.new_directory("dir2")

    command("Kivi")

    helper.search("dir1")
    command("KiviDo copy")

    helper.search("dir2")
    command("KiviDo child")

    command("KiviDo paste")

    helper.search("dir1")
    command("KiviDo child")

    assert.exists_pattern("file")

    command("KiviDo parent")
    command("KiviDo parent")
    assert.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can copy file and force paste", function()
    helper.new_file("file", [[test]])
    helper.new_directory("dir")
    helper.new_file("dir/file", [[overwrriten]])

    command("Kivi")

    helper.search("file")
    command("KiviDo copy")

    helper.search("dir")
    command("KiviDo child")

    helper.set_inputs("f")
    command("KiviDo paste")

    assert.exists_pattern("file")

    helper.search("file")
    command("KiviDo vsplit_open")
    assert.current_line("test")
    command("wincmd p")

    command("KiviDo parent")
    assert.exists_pattern("file")
  end)

  it("can copy directory and force paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file", [[test]])

    helper.new_directory("dir2")
    helper.new_directory("dir2/dir1")
    helper.new_file("dir2/dir1/file")

    command("Kivi")

    helper.search("dir1")
    command("KiviDo copy")

    helper.search("dir2")
    command("KiviDo child")

    helper.set_inputs("f")
    command("KiviDo paste")

    helper.search("dir1")
    command("KiviDo child")

    helper.search("file")
    command("KiviDo vsplit_open")
    assert.current_line("test")
  end)

  it("can copy file and rename paste", function()
    helper.new_file("file", [[test]])
    helper.new_directory("dir")
    helper.new_file("dir/file", [[ok]])

    command("Kivi")

    helper.search("file")
    command("KiviDo copy")

    helper.search("dir")
    command("KiviDo child")

    helper.set_inputs("r")
    command("KiviDo paste")

    command("s/file/renamed/")
    command("write")
    command("wincmd p")

    assert.exists_pattern("file")
    assert.exists_pattern("renamed")

    command("wincmd w")
    command("s/renamed/again/")
    command("write")
    command("wincmd p")

    assert.no.exists_pattern("renamed")
    assert.exists_pattern("again")
  end)

  it("can copy directory and rename paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file", [[test]])

    helper.new_directory("dir2")
    helper.new_directory("dir2/dir1")

    command("Kivi")

    helper.search("dir1")
    command("KiviDo copy")

    helper.search("dir2")
    command("KiviDo child")

    helper.set_inputs("r")
    command("KiviDo paste")

    command("s/dir1/renamed/")
    command("write")
    command("wincmd p")

    assert.exists_pattern("dir1")

    helper.search("renamed")
    command("KiviDo child")

    helper.search("file")
    command("KiviDo vsplit_open")
    assert.current_line("test")
  end)

  it("can cut file and paste", function()
    helper.new_file("file")
    helper.new_directory("dir")

    command("Kivi")

    helper.search("file")
    command("KiviDo cut")
    assert.exists_message("cut: .*file")

    helper.search("dir")
    command("KiviDo child")

    command("KiviDo paste")

    assert.exists_pattern("file")

    command("KiviDo parent")
    assert.no.exists_pattern("file")
  end)

  it("can cut directory and paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file")
    helper.new_directory("dir2")

    command("Kivi")

    helper.search("dir1")
    command("KiviDo cut")

    helper.search("dir2")
    command("KiviDo child")

    command("KiviDo paste")

    helper.search("dir1")
    command("KiviDo child")

    assert.exists_pattern("file")

    command("KiviDo parent")
    command("KiviDo parent")
    assert.no.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can paste empty", function()
    helper.new_file("file")

    command("Kivi")
    command("KiviDo paste")

    assert.exists_pattern("file")
  end)

  it("can rename file", function()
    helper.new_file("file")

    command("Kivi")
    command("KiviDo rename")

    assert.current_line("file")

    command("s/file/renamed/")
    command("wq")

    assert.no.exists_pattern("file")
    assert.exists_pattern("renamed")
  end)

  it("can rename directory", function()
    helper.new_directory("dir")

    command("Kivi")
    command("KiviDo rename")

    assert.current_line("dir/")

    command("s/dir/renamed/")
    command("wq")

    assert.no.exists_pattern("dir")
    assert.exists_pattern("renamed/")
  end)

  it("can create file in root", function()
    command("Kivi")

    command("KiviDo create")

    vim.fn.setline(1, "created")
    command("w")

    assert.exists_pattern("created")
  end)

  it("can create file in expanded tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file1")

    command("Kivi")

    helper.search("dir")
    command("KiviDo toggle_tree")

    helper.search("file1")
    command("KiviDo create")

    vim.fn.setline(1, "created")
    command("w")

    assert.exists_pattern("  created")
  end)

  it("can create directory", function()
    command("Kivi")

    command("KiviDo create")

    vim.fn.setline(1, "created/")
    command("w")

    assert.exists_pattern("created/")
  end)

  it("can create directory and file", function()
    command("Kivi")

    command("KiviDo create")

    vim.fn.setline(1, "created1/created2/file")
    command("w")

    assert.exists_pattern("created1/")
    assert.exists_pattern("  created2/")
    assert.exists_pattern("    file")
  end)

  it("can't create directory if it exists as file", function()
    helper.new_file("target")

    command("Kivi")

    command("KiviDo create")

    vim.fn.setline(1, "target/file")
    command("w")

    assert.exists_message(("can't create: %starget/file"):format(helper.test_data_dir))

    command("wincmd p")
    assert.no.exists_pattern("target/")
  end)

end)
