import type { AnyDataGraph, GraphEdge, GraphNode } from "../types.js";
import type { GraphDiff } from "./types.js";

export function diffGraph(before: AnyDataGraph, after: AnyDataGraph): GraphDiff {
  return {
    fromVersion: before.version,
    toVersion: after.version,
    addedNodes: after.nodes.filter((node) => !before.nodes.some((candidate) => candidate["@id"] === node["@id"])),
    removedNodes: before.nodes.filter((node) => !after.nodes.some((candidate) => candidate["@id"] === node["@id"])),
    addedEdges: after.edges.filter((edge) => !before.edges.some((candidate) => sameEdge(candidate, edge))),
    removedEdges: before.edges.filter((edge) => !after.edges.some((candidate) => sameEdge(candidate, edge))),
    updatedEdges: updatedEdges(before.edges, after.edges),
  };
}

function sameEdge(a: GraphEdge, b: GraphEdge): boolean {
  return a.from === b.from && a.to === b.to && a.relation === b.relation && a.domain === b.domain;
}

function sameNode(a: GraphNode, b: GraphNode): boolean {
  return a["@id"] === b["@id"];
}

function updatedEdges(before: GraphEdge[], after: GraphEdge[]): Array<{ before: GraphEdge; after: GraphEdge }> {
  const updates: Array<{ before: GraphEdge; after: GraphEdge }> = [];
  for (const oldEdge of before) {
    const newEdge = after.find((candidate) => sameEdge(candidate, oldEdge));
    if (newEdge && JSON.stringify(oldEdge) !== JSON.stringify(newEdge)) {
      updates.push({ before: oldEdge, after: newEdge });
    }
  }
  return updates;
}
