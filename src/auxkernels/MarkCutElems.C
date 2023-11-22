/****************************************************************/
/*             DO NOT MODIFY OR REMOVE THIS HEADER              */
/*          FALCON - Fracturing And Liquid CONvection           */
/*                                                              */
/*       (c)     2012 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#include "MarkCutElems.h"
#include "TraceRayTools.h"
#include "libmesh/mesh_tools.h"
#include "libmesh/enum_to_string.h"

registerMooseObject("FalconApp", MarkCutElems);

InputParameters
MarkCutElems::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription("Marks elements cut by mesh.");
  params.addRequiredParam<MeshFileName>("mesh_file", "Intersecting mesh file.");
  params.addParam<Real>("intersection_tolerance",
                        1.0,
                        "Tolerance for ray tracing algorithm to find intersection.  Element size is a good estimate.");
  return params;
}

MarkCutElems::MarkCutElems(const InputParameters & parameters)
  : AuxKernel(parameters),
  _cutter_mesh(loadCutterMesh(getParam<MeshFileName>("mesh_file"))),
  _intersection_tolerance(getParam<Real>("intersection_tolerance"))
{
  if (isNodal())
    paramError("variable", "The variable must be elemental");
  if (_mesh.dimension() != 3)
    mooseError("The mesh dimension must be 3D");

  buildCutterBoundingBoxes();
}

std::unique_ptr<const ReplicatedMesh>
MarkCutElems::loadCutterMesh(const MeshFileName & filename) const
{
  // Load the mesh from file
  std::unique_ptr<ReplicatedMesh> mesh = std::make_unique<ReplicatedMesh>(_communicator);
  mesh->read(filename);

  if (mesh->mesh_dimension() != 2)
    mooseError("The cutter mesh element dimension must be 2");

  // This lets us return a const mesh
  return std::unique_ptr<const ReplicatedMesh>(std::move(mesh));
}

void
MarkCutElems::buildCutterBoundingBoxes()
{
  _cutter_bboxes.clear();

  // Get the bounding box of this processor
  const auto pid_bbox = MeshTools::create_local_bounding_box(_mesh.getMesh());

  // Build the list of cut elems that may intersect this processor,
  // and store their bounding boxes
  for (const auto & elem : _cutter_mesh->element_ptr_range())
  {
    auto bbox = elem->loose_bounding_box();
    bbox.scale(1.01); // scale by a little for wiggle room in comparison
    if (pid_bbox.intersects(bbox))
      _cutter_bboxes.emplace_back(elem, bbox);
  }
}

void
MarkCutElems::meshChanged()
{
  buildCutterBoundingBoxes();
}

Real
MarkCutElems::computeValue()
{
  // The bounding box of the current element
  const auto bbox = _current_elem->loose_bounding_box();

  // Temproraries for doing things below
  std::unique_ptr<const Elem> edge;
  Real intersection_distance;
  ElemExtrema intersected_extrema;

  // Check intersection with each cut elem that intersects our local bbox
  for (const auto & [cut_elem, cut_bbox] : _cutter_bboxes)
  {
    // Bounding box of the cut elem doesn't intersect the current elem bbox
    // ...nothing to do here!
    if (!cut_bbox.intersects(bbox))
      continue;
    bool isQUAD = false;
    bool isTRI = false;
    switch (cut_elem->type())
    {
      case QUAD4:
      case QUAD8:
      case QUAD9:
        isQUAD = true;
        break;
      case TRI3:
      case TRI6:
      case TRI7:
        isTRI = true;
        break;
      default:
        mooseError("Element type ",
                   Utility::enum_to_string(cut_elem->type()),
                   " not supported in MarkCutEleme.C, it must be a TRI or QUAD type.");
    }

    // Check for an intersection with each edge and the cut tri
    // We have to check the intersection with each orientation of the edge
    for (const auto e : _current_elem->edge_index_range())
    {
      _current_elem->build_edge_ptr(edge, e);

      const auto & edge0 = edge->point(0);
      const auto & edge1 = edge->point(1);
      const auto edge_length = edge->volume();
      const auto direction = (edge0 - edge1) / edge_length;

      // Check for an intersection
      // We need to check both "directions" of the edge due to the
      // intersection algorithm
      if (isTRI &&
          (TraceRayTools::intersectTriangle(edge1,
                                            direction,
                                            cut_elem,
                                            0,
                                            1,
                                            2,
                                            intersection_distance,
                                            intersected_extrema,
                                            _intersection_tolerance) ||
           TraceRayTools::intersectTriangle(edge0,
                                            -direction,
                                            cut_elem,
                                            0,
                                            1,
                                            2,
                                            intersection_distance,
                                            intersected_extrema,
                                            _intersection_tolerance)) &&
          intersection_distance <= edge_length)
      {
        return 1;
      }
      else if (isQUAD &&
               (TraceRayTools::intersectQuad(edge1,
                                             direction,
                                             cut_elem,
                                             0,
                                             1,
                                             2,
                                             3,
                                             intersection_distance,
                                             intersected_extrema,
                                             _intersection_tolerance) ||
                TraceRayTools::intersectQuad(edge0,
                                             -direction,
                                             cut_elem,
                                             0,
                                             1,
                                             2,
                                             3,
                                             intersection_distance,
                                             intersected_extrema,
                                             _intersection_tolerance)) &&
               intersection_distance <= edge_length)
      {
        return 1;
      }
    }
  }

  return 0;
}
