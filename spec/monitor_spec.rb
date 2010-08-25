require "spec_helper"

require "fileutils"
require "tempfile"

module FSSM::MonitorSpecHelpers
  def create_tmp_dir
    @tmp_dir = Dir.mktmpdir
    FileUtils.cp_r File.join(File.dirname(__FILE__), 'root'), @tmp_dir
    # Because git does not track empty directories, create one ourselves.
    FileUtils.mkdir_p @tmp_dir + '/root/yawn'
    @tmp_dir
  end

  def remove_tmp_dir
    FileUtils.remove_entry_secure @tmp_dir
  end

  def create_handler(type)
    lambda {|base, relative| @handler_results[type] << [base, relative]}
  end

  def create_monitor
    @handler_results = Hash.new {|hash, key| hash[key] = []}
    @monitor = FSSM::Monitor.new
    @monitor.path(@tmp_dir) do |p|
      p.create(&create_handler(:create))
      p.update(&create_handler(:update))
      p.delete(&create_handler(:delete))
    end
    sleep 1     # give time for monitor to preload
  end

  def run_monitor
    thread = Thread.new {@monitor.run}
    sleep 2     # give time for monitor to see changes
    thread.kill
  end
end

describe "The File System State Monitor" do
  describe "monitor" do
    include FSSM::MonitorSpecHelpers

    before do
      create_tmp_dir
      create_monitor
    end

    after do
      remove_tmp_dir
    end

    it "should call create callback upon file creation" do
      file = @tmp_dir + "/newfile.rb"
      File.exists?(file).should be_false
      FileUtils.touch file
      run_monitor
      @handler_results[:create].should == [[@tmp_dir, 'newfile.rb']]
    end

    it "should call update callback upon file modification" do
      FileUtils.touch @tmp_dir + '/root/file.rb'
      run_monitor
      @handler_results[:update].should == [[@tmp_dir, 'root/file.rb']]
    end

    it "should call delete callback upon file deletion" do
      FileUtils.rm @tmp_dir + "/root/file.rb"
      run_monitor
      @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
    end

    it "should call create and delete callbacks upon file renaming in the same directory" do
      FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/root/old_file.rb"
      run_monitor
      @handler_results[:create].should == [[@tmp_dir, 'root/old_file.rb']]
      @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
      @handler_results[:update].should == []
    end

    it "should call create and delete callbacks upon file moving to another directory" do
      FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/old_file.rb"
      run_monitor
      @handler_results[:create].should == [[@tmp_dir, 'old_file.rb']]
      @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
      @handler_results[:update].should == []
    end

    it "should not call callbacks upon directory operations" do
      FileUtils.mkdir @tmp_dir + "/another_yawn"
      FileUtils.rmdir @tmp_dir + "/root/yawn"
      run_monitor
      @handler_results[:create].should == []
      @handler_results[:delete].should == []
    end
  end
end
