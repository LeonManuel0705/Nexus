

import FlutterMacOS
import Foundation

import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}
