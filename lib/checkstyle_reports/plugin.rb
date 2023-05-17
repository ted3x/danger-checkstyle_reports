# frozen_string_literal: true

require 'pathname'
require 'rexml/document'

require_relative 'gem_version'

require_relative 'lib/severity'

require_relative 'entity/found_error'
require_relative 'entity/found_file'

module Danger
  # Comment checkstyle reports.
  #
  # You need to specify the project root. You don't need do it if it is same with git's top-level path.
  #
  #         checkstyle_reports.root_path=/path/to/project
  #
  # @example Report errors whose files have been modified (By default)
  #
  #         checkstyle_reports.report("app/build/checkstyle/checkstyle.xml"[, modified_files_only: true])
  #
  # @example Report all errors in app/build/checkstyle/checkstyle.xml
  #
  #         checkstyle_reports.report("app/build/checkstyle/checkstyle.xml", modified_files_only: false)
  #
  # @see  Jumpei Matsuda/danger-checkstyle_reports
  # @tags android, checkstyle
  #
  class DangerCheckstyleReports < Plugin
    REPORT_METHODS = %i[message warn fail].freeze

    # *Optional*
    # An absolute path to a root.
    # To comment errors to VCS, this needs to know relative path of files from the root.
    #
    # @return [String] the root path of git repository by default.
    attr_accessor :root_path

    # *Optional*
    # Create inline comment if true.
    #
    # @return [Boolean] true by default
    attr_accessor :inline_comment

    # *Optional*
    # minimum severity to be reported (inclusive)
    #
    # @return [String, Symbol] error by default
    attr_accessor :min_severity

    # *Optional*
    # Set report method
    #
    # @return [String, Symbol] error by default
    attr_accessor :report_method

    # Enable filtering
    # Only show messages within changed files.
    attr_accessor :filtering

    # Only show messages for the modified lines.
    attr_accessor :filtering_lines

    # The array of files which include at least one error
    #
    # @return [Array<String>] a collection of relative paths
    attr_reader :reported_files

    # Report errors based on the given xml file if needed
    #
    # @param [String] xml_file which contains checkstyle results to be reported
    # @param [Boolean] modified_files_only which is a flag to filter out non-added/non-modified files
    # @return [void] void
    def report(xml_file, modified_files_only: true)
      raise 'File path must not be empty' if xml_file.empty?
      raise 'File not found' unless File.exist?(xml_file)

      @min_severity = (min_severity || :error).to_sym
      @report_method = (report_method || :fail).to_sym

      raise 'Unknown severity found' unless CheckstyleReports::Severity::VALUES.include?(min_severity)
      raise 'Unknown report method' unless REPORT_METHODS.include?(report_method)

      files = parse_xml(xml_file, modified_files_only)

      @reported_files = files.map(&:relative_path)

      do_comment(files) unless files.empty?
    end

    private

    # Parse the given xml file and apply filters if needed
    #
    # @param [String] file_path which is a check-style xml file
    # @param [Boolean] modified_files_only a flag to determine to apply added/modified files-only filter
    # @return [Array<FoundFile>] filtered files
    def parse_xml(file_path, modified_files_only)
      prefix = root_path || `git rev-parse --show-toplevel`.chomp

      files = []

      REXML::Document.new(File.read(file_path)).root.elements.each('file') do |f|
        files << CheckstyleReports::Entity::FoundFile.new(f, prefix: prefix)
      end

      if modified_files_only
        target_files = git.modified_files + git.added_files

        files.select! { |f| target_files.include?(f.relative_path) }
      end

      files.reject!(&:errors_empty?)
      files
    end

    # Comment errors based on the given xml file to VCS
    #
    # @param [Array<FoundFile>] files which contains checkstyle results to be reported
    # @return [void] void
    def do_comment(files)
      base_severity = CheckstyleReports::Severity.new(min_severity)
      target_files = git.modified_files + git.added_files
      target_lines = {}

      if filtering_lines
        target_files.each do |file|
          added_lines = parse_added_line_numbers(git.diff[file].patch)
          target_lines[file] = added_lines
        end
      end

      files.each do |f|
        f.errors.each do |e|
          # check severity
          next unless base_severity <= e.severity

          if filtering_lines
            next unless target_files.include?(f.relative_path)
            added_lines = target_lines[f.relative_path]
            next unless added_lines.include?(e.line_number)
          end

          if inline_comment
            public_send(report_method, e.html_unescaped_message, file: f.relative_path, line: e.line_number)
          else
            public_send(report_method, "#{f.relative_path} : #{e.html_unescaped_message} at #{e.line_number}")
          end
        end
      end
    end

    # Parses git diff of a file and returns an array of added line numbers.
    def parse_added_line_numbers(diff)
      current_line_number = nil
      added_line_numbers = []
      diff_lines = diff.strip.split("\n")
      diff_lines.each_with_index do |line, index|
        if (m = %r{\+(\d+)(?:,\d+)? @@}.match(line))
          # (e.g. @@ -32,10 +32,7 @@)
          current_line_number = Integer(m[1])
        else
          if !current_line_number.nil?
            if line.start_with?('+')
              # added line
              added_line_numbers.push(current_line_number)
              current_line_number += 1
            elsif !line.start_with?('-')
              # unmodified line
              current_line_number += 1
            end
          end
        end
      end
      added_line_numbers
    end
  end
end
