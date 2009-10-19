require File.dirname(__FILE__) + '/test_helper.rb'

class LabeledMatrix < Test::Unit::TestCase

  def setup
    @two_by_three = EditAlign::LabeledMatrix.new(['A', 'B'], ['C', 'D', 'E'])
  end
  
  def test_attributes
    assert_equal(['A', 'B'], @two_by_three.col_labels)
    assert_equal(['C', 'D', 'E'], @two_by_three.row_labels)
    assert_equal(2, @two_by_three.num_cols)
    assert_equal(3, @two_by_three.num_rows)
  end
  
  def test_enumeration
    items = []
    @two_by_three.each_item {|item| items << item}
    assert_equal([EditAlign::INFINITY] * 6, items)
  end
  
  def test_stringification
    # Basic
    expected =<<-EOTEXT
  A B
C * *
D * *
E * *
EOTEXT
    assert_equal(expected.chomp, @two_by_three.to_s)
    # Long field
    m = EditAlign::LabeledMatrix.new(['A', 'B'], ['C', 'D'])
    m[0][0] = 1
    m[0][1] = 2
    m[1][0] = 3
    m[1][1] = 4
    expected =<<-EOTEXT
   A    B
C 1.00 2.00
D 3.00 4.00
EOTEXT
    assert_equal(expected.chomp, m.to_s)
    # Long row label
    m = EditAlign::LabeledMatrix.new(['A', 'B'], ['Long', 'D'])
    expected =<<-EOTEXT
     A B
Long * *
D    * *
EOTEXT
    assert_equal(expected.chomp, m.to_s)
  end
end


class WeightedDirectedGraph < Test::Unit::TestCase
  def setup
    @g = EditAlign::WeightedDirectedGraph['a', 'b', 2, 'b', 'c', 3, 'a', 'c', 6]
  end
  
  def test_stringification
    expected =<<-EOTEXT
(a-2-b)
(a-6-c)
(b-3-c)
EOTEXT
    assert_equal(expected.chomp, @g.to_s)
    # Make the 'c' node isolated.
    @g.remove_edge('b', 'c')
    @g.remove_edge('a', 'c')
    expected =<<-EOTEXT
(a-2-b)
c
EOTEXT
    assert_equal(expected.chomp, @g.to_s)
  end
  
  def test_enum_nodes
    nodes = []
    @g.each {|n| nodes << n}
    assert_equal(['a', 'b', 'c'], nodes.sort)
  end
  
  def test_enum_adjacent_nodes
    nodes = []
    @g.each_adjacent('a') {|n| nodes << n}
    assert_equal(['b', 'c'], nodes.sort)
    nodes = []
    @g.each_adjacent('b') {|n| nodes << n}
    assert_equal(['c'], nodes.sort)
    nodes = []
    @g.each_adjacent('c') {|n| nodes << n}
    assert_equal([], nodes.sort)
  end
  
  def test_weight
    assert_equal(2, @g.weight('a', 'b'))
    assert_equal(3, @g.weight('b', 'c'))
    assert_equal(6, @g.weight('a', 'c'))
  end
end


class ExhaustiveSearch < Test::Unit::TestCase
  def test_exhaustive_search
    
  end
  # def test_exhaustive_search
  #   cost, backtrace = EditAlign.exhaustive_grid_search(['a', 'c'], ['a', 'b', 'c']) do |op, arg|
  #     case op
  #     when :insert
  #       1
  #     when :delete
  #       1
  #     when :substitute
  #       arg[0] == arg[1] ? 1 : 0
  #     else
  #       raise ArgumentError.new("Invalid edit operation #{op}")
  #     end
  #   end
  #   # puts cost.to_s
  #   # puts backtrace.inspect
  # end
  
end


class DijkstraSearch < Test::Unit::TestCase
  def test_three_node_graph
    # a --2-- b
    #   \     |
    #     6   3
    #      \  |
    #         c
    g = EditAlign::WeightedDirectedGraph['a', 'b', 2, 'b', 'c', 3, 'a', 'c', 6]
    s = EditAlign::Dijkstra.new('a', 'c', g)
    assert_equal([[2, ["a", "b", "c"]], [6, ["a", "c"]]], s.collect)
  end
end
