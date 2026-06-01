//
//  ADAR2MLVisualizerModel.swift
//  ADAR2MLVisualizer
//
//  Created by Alex Frankiv on 29.10.2024.
//
import Foundation

public enum ADAR2MLVisualizerModel: String, CaseIterable {

    case gnn_2L_5000 = "gnn_2-L_model_5000"
    case gnn_3L_5000 = "gnn_3-L_model_5000"
    case gnn_4L_5000 = "gnn_4-L_model_5000"

    var outputVariableName: String {
        switch self {
        case .gnn_2L_5000: "var_163"
        case .gnn_3L_5000: "var_241"
        case .gnn_4L_5000: "var_319"
        }
    }
}
