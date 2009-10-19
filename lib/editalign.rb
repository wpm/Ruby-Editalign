$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

$KCODE="u"
require "editalign/alignments"
require "editalign/dijkstra"
require "editalign/graph"
require "editalign/exhaustive"

require "jcode"
require "logger"
require "set"


module EditAlign
  VERSION = '0.0.1'
  
  INFINITY = 1.0/0.0

  # Create the logger and set its default log level to ERROR.  This function
  # is called when the module is loaded.
  def EditAlign.initialize_logger
    logger = Logger.new(STDERR)
    logger.level = Logger::ERROR
    logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    logger
  end


  private_class_method :initialize_logger


  # Logger used by all objects in this module.  This is initialized at module
  # load time.  The default log level is ERROR.
  LOGGER = initialize_logger


  # Set the logging level.
  #
  # [_level_] a constant from the
  #           Logger[http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc]
  #           module.
  #
  #   > EditAlign.set_log_level(Logger::DEBUG)
  def EditAlign.set_log_level(level)
    EditAlign::LOGGER.level = level
  end


  # A matrix of numbers with labels on the rows and columns.
  class LabeledMatrix < Array

    attr_reader :col_labels, :row_labels

    # Create the matrix, specifying the row and column labels.  The initial
    # values in all the cells in INFINITY.
    #
    # * col_labels:: an array of labels for the columns
    # * row_labels:: an array of labels for the rows
    def initialize(col_labels, row_labels)
      @col_labels = col_labels
      @row_labels = row_labels
      row_labels.each { |r| self << [INFINITY] * col_labels.length }
    end
    
    # TODO Why doesn't each get called if I subclass it here?
    
    # Enumerate all the items.
    def each_item
      each {|row| row.each { |item| yield item }}
    end

    # The number of columns in the matrix.
    def num_cols
      col_labels.length
    end

    # The number of rows in the matrix.
    def num_rows
      row_labels.length
    end

    # Return the table as a grid.
    def to_s
      # The widest item in the table is used to set the width of all the
      # columns.
      item_width = widest_item
      row_label_width = row_labels.map { |label| label.to_s.jlength }.max
      # Enumerate rows prepending column labels.
      ([col_labels] + self).zip([" "] + row_labels).map do |row, row_label|
        # Enumerate row items prepending row labels.
        ([sprintf("%-#{row_label_width}s", row_label)] + row.map do |item|
          # Center each item in a space as wide as the widest column.
          item_to_s(item).center(item_width)
        end).join(" ").rstrip
      end.join("\n")
    end

    # The widest string field in the table, including the column labels.
    def widest_item
      widest = col_labels.map { |label| label.to_s.jlength }
      each_item {|item| widest << item_to_s(item).jlength }
      widest.max
    end

    # Stringify items in the matrix.  Infnity is mapped to "*" and numeric
    # values are printed with 2 decimal points of precision.
    #
    # item:: an item in the matrix or a label
    def item_to_s(item)
      if item == INFINITY
        "*"
      elsif item.is_a?(Numeric)
        sprintf("%0.2f", item)
      else
        item.to_s
      end
    end

    private :item_to_s, :widest_item

  end
  
end