require "rgl/adjacency"

module EditAlign

  # A weighted directed graph.
  class WeightedDirectedGraph < RGL::DirectedAdjacencyGraph
    def initialize(edgelist_class = Set, *other_graphs)
      super
      @weights = {}
    end

    # Create a graph from an array of [source, target, weight] triples.
    #
    #  >> g=EditAlign::WeightedDirectedGraph[:a, :b, 2, :b, :c, 3, :a, :c, 6]
    #  >> puts g
    #  (a-2-b)
    #  (a-6-c)
    #  (b-3-c)
    def self.[] (*a)
      result = new
      0.step(a.size-2, 3) { |i| result.add_edge(a[i], a[i+1], a[i+2]) }
      result
    end

    def to_s
      # TODO Sort toplogically instead of by edge string.
      (edges.sort_by {|e| e.to_s} + 
       isolates.sort_by {|n| n.to_s}).map { |e| e.to_s }.join("\n")
    end

    # A set of all the unconnected vertices in the graph.
    def isolates
      edges.inject(Set.new(vertices)) { |iso, e| iso -= [e.source, e.target] }
    end

    # Add a weighted edge between two verticies.
    #
    # [_u_] source vertex
    # [_v_] target vertex
    # [_w_] weight
    def add_edge(u, v, w)
      super(u,v)
      @weights[[u,v]] = w
    end

    # Edge weight
    #
    # [_u_] source vertex
    # [_v_] target vertex
    def weight(u, v)
      @weights[[u,v]]
    end

    # Remove the edge between two verticies.
    #
    # [_u_] source vertex
    # [_v_] target vertex
    def remove_edge(u, v)
      super
      @weights.delete([u,v])
    end

    # The class used for edges in this graph.
    def edge_class
      WeightedDirectedEdge
    end

    # Return the array of WeightedDirectedEdge objects of the graph.
    def edges
      result = []
      c = edge_class
      each_edge { |u,v| result << c.new(u, v, self) }
      result
    end

  end


  # A directed edge that can display its weight as part of stringification.
  class WeightedDirectedEdge < RGL::Edge::DirectedEdge
    
    # [_u_] source vertex
    # [_v_] target vertex
    # [_g_] the graph in which this edge appears
    def initialize(a, b, g)
      super(a,b)
      @graph = g
    end

    # The weight of this edge.
    def weight
      @graph.weight(source, target)
    end

     def to_s
       "(#{source}-#{weight}-#{target})"
     end
  end


  # TODO Rewrite as an ImplicitGraph

  # A representeation of an edit alignment cost grid as a directed graph where
  # nodes are cells in the grid, edges are edit operations, and edge weights
  # are taken from the weighting funcion.
  #
  # Nodes are represented as ordered pairs of integers [_i_,_j_] where _i_ is
  # an index into the _from_ array and _j_ is an index into the _to_ array.
  #
  # By default all nodes have edges to nodes diagonally [_i_+1,_j_+1],
  # vertically [_i_,_j_+1], and horizontally [_i_+1,j] adjacent in the grid.
  # These edges represent the substitution, insertion, and deletion operations
  # respectively, and their weights are obtained from the _weight_ function.
  # The caller may remove edges.
  class AlignmentGraph < WeightedDirectedGraph
    # Create an graph from an edit alignment grid specified by column and row
    # labels and a weighting function.
    #
    # [_cols_] an Array of column labels
    # [_rows_] an Array of row labels
    # [_weight_] a weighting function
    def initialize(cols, rows, &weight)
      super([0,0], [cols.length-1, rows.length-1])
      @cols = cols
      @rows = rows
      @weight = weight
      @deleted = @cost[]
    end

    # Eumerate all the nodes in the graph.
    def each
      @cols.length.times do |i|
        @rows.length.times do |j|
          yield [i, j]
        end
      end
    end

    # Remove an edge from the graph.
    def remove_edge(col, row)
      @deleted << [col, row]
    end

    # Enumerate the nodes in the graph adjacent to the specifed one along with
    # the weights of the edges between them.
    #
    # [_node_] a node in the graph, an ordered pair of integer indexes
    def each_adjacent(node)
      # TODO Return costs from cost function.
      # Yield nodes corresponding to substitution, insertion, and deletion
      # operations if the edges have not been deleted from the graph.
      i = node[0]
      j = node[1]
      # Move diagonally to yield a substitution.
      if i < @cols.length-1 and j < @rows.length-1 and
        not @deleted.include?([i+1, j+1])
        col_item = @cols[i+1]
        row_item = @rows[j+1]
        yield [[i+1, j+1], @weighted.call(:substitue, [col_item, row_item])]
      end
      # Move vertically to yield an insertion.
      if j < @rows.length-1 and not @deleted.include?([i, j+1])
        yield [[i, j+1], @weighted.call(:insert, @rows[j+1])]
      end
      # Move horizontally to yield a deletion.
      if i < @cols.length-1 and not @deleted.include?([i+1,j])
        yield [[i+1, j], @weighted.call(:insert, @cols[i])]
      end
    end

    def weight(from, to)
      # TODO Implement
    end
  end

end