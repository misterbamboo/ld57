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
        
func render_map(square_generator: MarchingSquaresGenerator, from_y: int, to_y: int, width: int):
    polygon_index = 0
    var polygons = []
    
    for x in range(width):
        for y in range(from_y, to_y):
            var points = square_generator.generate_polygon_points(x, y, cell_size)
            if points.size() >= 3:
                polygons.append(points)
                
    for poly_points in polygons:
        var poly = _get_next_polygon()
        poly.visible = true
        poly.polygon = PackedVector2Array(poly_points)
        
    # Hide unused polygons
    for i in range(polygon_index, polygon_pool.size()):
        polygon_pool[i].visible = false
        
func hide_all():
    for poly in polygon_pool:
        poly.visible = false
