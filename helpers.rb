#!/usr/bin/ruby

require 'thor'

module Helpers
  class Git < Thor
    desc 'filterdiff <against_commit> <regex>', '(alias fdiff) List files where regex matches any line of diff'
    option :edit, :desc=>'open matched files in $EDITOR'
    def filterdiff(commit, filter)
      pattern = Regexp.new(filter)
      all_files = `git diff --name-only #{commit}`
      matched_files = []
      all_files.strip.split(/\s+/).each do |f|
        s = `git diff #{commit} #{f}`
        if !s.valid_encoding?
          s = s.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
        end
        s.each_line do |line|
          if pattern =~ line then
            matched_files << f
            break
          end
        end
      end
      if options[:edit] then
        Kernel.exec("#{ENV['EDITOR']} #{matched_files.join(" ")}")
      else
        puts matched_files.join("\n")
      end
    end

    desc 'commitbranch <commit_msg_and_branch_name> [branch_name]', '(alias cb) Commit current changes to new branch and go back'
    def commitbranch(name, branch_name=nil)
      if branch_name.nil? then
        branch_name = name
      end
      current_branch = `git rev-parse --abbrev-ref HEAD`
      Kernel.system("git checkout -b #{branch_name}")
      Kernel.system("git add .")
      Kernel.system("git commit -m #{name}")
      Kernel.system("git checkout #{current_branch}")
    end

    map :fdiff => :filterdiff
    map :cb => :commitbranch
  end

  class Os < Thor
    desc 'sleepin <n minutes> [--background]', 'systemctl suspend in n minutes'
    option :background, :desc => 'wait in background process'
    def sleepin(mintues)
      if options[:background]
        exit if Kernel.fork
      end
      sleep(mintues.to_i * 60)
      Kernel.exec('systemctl suspend')
    end
  end

  class Install < Thor
    desc 'java <path/to/oracle_java.rpm>', 'install Oracle java from downloaded rpm package. Make sure `alien` is installed'
    def java(rpm)
      system("alien --install #{rpm}")
      unpack200 = Dir["/usr/java/**/bin/unpack200"].first
      Dir["/usr/java/**/*.pack"].map {|f| `#{unpack200} #{f} #{File.dirname(f)+'/'+File.basename(f, ".*")}.jar`}
    end
  end

  class Go < Thor
    desc 'pprofmon <binary> <pprof_dump_url> [--interval] [--output]', 'make pprof dumps + svg graphs by interval (5s default) to specified output (./pprofmon default)'
    option :interval, :type=>:numeric, :default=>1, :desc=>'pprof dump interval'
    option :output, :type=>:string, :deafult=>'./pprofmon/', :desc=>'set dumps output directory'
    option :verbose, :type=>:boolean, :default=>false
    def pprofmon(binary, dump_url)
      if binary.nil? || dump_url.nil?
        p 'invalid invocation, see help'
        exit 1
      end
      output = options[:output] || './ppromon'
      interval = options[:interval].to_i || 1

      p "Setting output to #{output}"
      `mkdir -p #{output}`

      verbose "carbon-copy #{binary} to #{output}"
      `cp #{binary} #{File.join(output, binary)}`

      p "starting #{binary}"
      pid = fork { exec binary }

      loop {
        verbose "sleeping #{interval} seconds"
        sleep interval
        if (Process.getpgid(pid) rescue nil).nil?
          puts "#{binary} is no longer running. See results in #{output}"
          exit 0
        end
        now = Time.now.to_s.gsub(' ', '_')
        profpath = File.join("#{output}","#{now}.prof")
        svgpath = File.join("#{output}","#{now}.svg")
        verbose "saving #{profpath}"
        `curl #{dump_url} > #{profpath}`
        verbose "generating #{svgpath}"
        `go tool pprof -svg #{binary} #{profpath} > #{svgpath}`
      }
    end

    private
    def verbose(s)
      p(s) if options[:verbose]
    end
  end

  class Helpers < Thor
    desc 'git SUBCOMMAND ...ARGS', 'git helpers'
    subcommand 'git', Git

    desc 'os SUBCOMMAND ...ARGS', 'OS helpers'
    subcommand 'os', Os

    desc 'install SUBCOMMAND ...ARGS', 'install scripts for not easy apt-gettable things'
    subcommand 'install', Install

    desc 'go SUBCOMMAND ...ARGS', 'golang tools'
    subcommand 'go', Go
  end

end

Helpers::Helpers.start(ARGV)
