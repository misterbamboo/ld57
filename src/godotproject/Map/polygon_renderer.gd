class_name PolygonRenderer extends MapRenderer

var node: Node2D
var polygon_pool: Array[Polygon2D] = []
var pool_size: int
var polygon_index: int = 0
var polygon_color: Color = Color(0.8, 0.7, 0.5)
var cell_size: int

func _init(parent_node: Node2D, pool_sz: int, cell_sz: int):
    node = parent_node
    pool_size = pool_sz
    cell_size = cell_sz
    _init_pool()
    
func _init_pool():
    for i in pool_size:
        create_polygon()
        
func create_polygon() -> Polygon2D:
    var poly = Polygon2D.new()
    poly.color = polygon_color
    poly.visible = false
    polygon_pool.append(poly)
    node.add_child(poly)
    return poly
    
func _get_next_polygon() -> Polygon2D:
    if polygon_index < polygon_pool.size():
        var poly = polygon_pool[polygon_index]
        polygon_index += 1
        return poly
    else:
        polygon_index += 1
        return create_polygon()
        
# Implementation of parent class abstract method for 2D map rendering
func render_map(square_generator: MarchingSquaresGenerator, x_from: int, x_to: int, y_from: int, y_to: int):
    if Engine.is_editor_hint():
        return
        
    # Reset the polygon index and clear existing polygons
    polygon_index = 0
    for poly in polygon_pool:
        poly.visible = false
    
    # Generate polygons for the specified map region
    for x in range(x_from, x_to):
        for y in range(y_from, y_to):
            var square_type = square_generator.get_square_value(x, y)
            if square_type == 0:
                continue
                
            # Get or create a polygon for this cell
            var polygon = _get_next_polygon()
            polygon.visible = true
            
            # Calculate polygon vertices based on cell position
            var vertices = PackedVector2Array()
            vertices.append(Vector2(x * cell_size, y * cell_size))
            vertices.append(Vector2((x + 1) * cell_size, y * cell_size))
            vertices.append(Vector2((x + 1) * cell_size, (y + 1) * cell_size))
            vertices.append(Vector2(x * cell_size, (y + 1) * cell_size))
            
            polygon.polygon = vertices
            polygon_index += 1

func hide_all():
    for poly in polygon_pool:
        poly.visible = false

# Implementation of applying cached chunk data
func apply_cached_chunk(chunk_data, x_from: int, y_from: int):
    if Engine.is_editor_hint() or chunk_data == null:
        return
        
    # Reset the polygon index and clear existing polygons
    polygon_index = 0
    for poly in polygon_pool:
        poly.visible = false
    
    # Apply the cached tile data
    for y_offset in range(chunk_data.size()):
        var y = y_from + y_offset
        var row = chunk_data[y_offset]
        
        for x_offset in range(row.size()):
            var x = x_from + x_offset
            var square_type = row[x_offset]
            
            if square_type == 0:
                continue
                
            # Get or create a polygon for this cell
            var polygon = _get_next_polygon()
            polygon.visible = true
            
            # Calculate polygon vertices based on cell position
            var vertices = PackedVector2Array()
            vertices.append(Vector2(x * cell_size, y * cell_size))
            vertices.append(Vector2((x + 1) * cell_size, y * cell_size))
            vertices.append(Vector2((x + 1) * cell_size, (y + 1) * cell_size))
            vertices.append(Vector2(x * cell_size, (y + 1) * cell_size))
            
            polygon.polygon = vertices
