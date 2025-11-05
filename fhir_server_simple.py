#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🩺 Servidor FHIR Simple para Colombia
Servidor básico para probar recursos FHIR sin necesidad de Docker
"""

from flask import Flask, request, jsonify
import json
import uuid
from datetime import datetime
import os

# Crear aplicación Flask
app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # Para caracteres UTF-8

# Almacén en memoria para recursos FHIR
fhir_store = {
    "Patient": {},
    "Practitioner": {},
    "Organization": {},
    "Condition": {},
    "Encounter": {},
    "MedicationAdministration": {}
}

# Contador de recursos creados
resource_counter = {
    "Patient": 0,
    "Practitioner": 0,
    "Organization": 0,
    "Condition": 0,
    "Encounter": 0,
    "MedicationAdministration": 0
}

@app.route('/', methods=['GET'])
def home():
    """Página principal con información del servidor"""
    return jsonify({
        "message": "🩺 Servidor FHIR Simple para Colombia",
        "version": "1.0.0",
        "description": "Servidor básico para desarrollo y pruebas de interoperabilidad",
        "endpoints": {
            "metadata": "/fhir/metadata",
            "base": "/fhir",
            "recursos": {
                "Patient": "/fhir/Patient",
                "Practitioner": "/fhir/Practitioner",
                "Organization": "/fhir/Organization",
                "Condition": "/fhir/Condition"
            }
        },
        "estadisticas": resource_counter,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/fhir/metadata', methods=['GET'])
def capability_statement():
    """CapabilityStatement - Describe las capacidades del servidor FHIR"""
    return jsonify({
        "resourceType": "CapabilityStatement",
        "id": "simple-fhir-server-colombia",
        "url": "http://localhost:5000/fhir/metadata",
        "version": "1.0.0",
        "name": "SimpleFHIRServerColombia", 
        "title": "Servidor FHIR Simple para Colombia",
        "status": "active",
        "experimental": True,
        "date": datetime.now().isoformat(),
        "publisher": "Proyecto Interoperabilidad Colombia",
        "description": "Servidor FHIR básico para desarrollo y pruebas de interoperabilidad en salud",
        "kind": "instance",
        "software": {
            "name": "Simple FHIR Server",
            "version": "1.0.0",
            "releaseDate": "2025-11-04"
        },
        "implementation": {
            "description": "Implementación básica de servidor FHIR para Colombia",
            "url": "http://localhost:5000/fhir"
        },
        "fhirVersion": "4.0.1",
        "format": [
            "application/fhir+json",
            "application/json"
        ],
        "rest": [{
            "mode": "server",
            "documentation": "Servidor FHIR básico con operaciones CRUD",
            "security": {
                "description": "Sin autenticación (solo para desarrollo)"
            },
            "resource": [
                {
                    "type": "Patient",
                    "interaction": [
                        {"code": "create"},
                        {"code": "read"},
                        {"code": "search-type"}
                    ],
                    "searchParam": [
                        {"name": "identifier", "type": "token"},
                        {"name": "family", "type": "string"},
                        {"name": "given", "type": "string"}
                    ]
                },
                {
                    "type": "Practitioner", 
                    "interaction": [
                        {"code": "create"},
                        {"code": "read"},
                        {"code": "search-type"}
                    ]
                },
                {
                    "type": "Organization",
                    "interaction": [
                        {"code": "create"},
                        {"code": "read"},
                        {"code": "search-type"}
                    ]
                },
                {
                    "type": "Condition",
                    "interaction": [
                        {"code": "create"},
                        {"code": "read"},
                        {"code": "search-type"}
                    ]
                }
            ]
        }]
    })

@app.route('/fhir', methods=['GET'])
def fhir_base():
    """Endpoint base FHIR con estadísticas"""
    return jsonify({
        "message": "🩺 Base FHIR - Servidor Simple Colombia",
        "servidor": "Simple FHIR Server v1.0.0",
        "recursos_disponibles": list(fhir_store.keys()),
        "estadisticas": resource_counter,
        "total_recursos": sum(resource_counter.values()),
        "endpoints_utiles": {
            "metadata": "/fhir/metadata",
            "crear_paciente": "POST /fhir/Patient",
            "buscar_pacientes": "GET /fhir/Patient",
            "obtener_paciente": "GET /fhir/Patient/{id}"
        },
        "ejemplo_uso": {
            "crear": "curl -X POST -H 'Content-Type: application/fhir+json' -d @Patient.json http://localhost:5000/fhir/Patient",
            "buscar": "curl http://localhost:5000/fhir/Patient",
            "metadata": "curl http://localhost:5000/fhir/metadata"
        }
    })

@app.route('/fhir/<resource_type>', methods=['POST'])
def create_resource(resource_type):
    """Crear un nuevo recurso FHIR"""
    try:
        # Validar que el tipo de recurso es soportado
        if resource_type not in fhir_store:
            return jsonify({
                "error": f"Tipo de recurso '{resource_type}' no soportado",
                "tipos_soportados": list(fhir_store.keys())
            }), 400
        
        # Obtener datos del request
        data = request.get_json()
        if not data:
            return jsonify({"error": "Cuerpo de la petición vacío"}), 400
        
        # Validar que es un recurso FHIR válido
        if 'resourceType' not in data:
            data['resourceType'] = resource_type
        elif data['resourceType'] != resource_type:
            return jsonify({
                "error": f"resourceType '{data['resourceType']}' no coincide con la URL '{resource_type}'"
            }), 400
        
        # Generar ID único
        resource_id = str(uuid.uuid4())
        data['id'] = resource_id
        
        # Agregar metadatos
        data['meta'] = {
            "versionId": "1",
            "lastUpdated": datetime.now().isoformat(),
            "profile": [f"http://hl7.org/fhir/StructureDefinition/{resource_type}"]
        }
        
        # Almacenar recurso
        fhir_store[resource_type][resource_id] = data
        resource_counter[resource_type] += 1
        
        # Log para debugging
        print(f"✅ Recurso {resource_type} creado:")
        print(f"   📋 ID: {resource_id}")
        print(f"   📊 Total {resource_type}: {resource_counter[resource_type]}")
        
        # Retornar recurso creado con status 201
        return jsonify(data), 201
        
    except json.JSONDecodeError:
        return jsonify({"error": "JSON inválido en el cuerpo de la petición"}), 400
    except Exception as e:
        print(f"❌ Error creando {resource_type}: {str(e)}")
        return jsonify({"error": f"Error interno: {str(e)}"}), 500

@app.route('/fhir/<resource_type>/<resource_id>', methods=['GET'])
def get_resource(resource_type, resource_id):
    """Obtener un recurso específico por ID"""
    try:
        if resource_type not in fhir_store:
            return jsonify({"error": f"Tipo de recurso '{resource_type}' no soportado"}), 400
        
        resource = fhir_store[resource_type].get(resource_id)
        if resource:
            print(f"📖 Recurso {resource_type}/{resource_id} consultado")
            return jsonify(resource)
        else:
            return jsonify({
                "error": f"Recurso {resource_type}/{resource_id} no encontrado"
            }), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/fhir/<resource_type>', methods=['GET'])
def search_resources(resource_type):
    """Buscar recursos de un tipo específico"""
    try:
        if resource_type not in fhir_store:
            return jsonify({"error": f"Tipo de recurso '{resource_type}' no soportado"}), 400
        
        resources = fhir_store[resource_type]
        
        # Crear Bundle FHIR para los resultados
        bundle = {
            "resourceType": "Bundle",
            "id": str(uuid.uuid4()),
            "meta": {
                "lastUpdated": datetime.now().isoformat()
            },
            "type": "searchset",
            "total": len(resources),
            "link": [
                {
                    "relation": "self",
                    "url": f"http://localhost:5000/fhir/{resource_type}"
                }
            ],
            "entry": [
                {
                    "fullUrl": f"http://localhost:5000/fhir/{resource_type}/{resource_id}",
                    "resource": resource,
                    "search": {
                        "mode": "match"
                    }
                }
                for resource_id, resource in resources.items()
            ]
        }
        
        print(f"🔍 Búsqueda {resource_type}: {len(resources)} recursos encontrados")
        return jsonify(bundle)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/fhir/<resource_type>/<resource_id>', methods=['DELETE'])
def delete_resource(resource_type, resource_id):
    """Eliminar un recurso específico"""
    try:
        if resource_type not in fhir_store:
            return jsonify({"error": f"Tipo de recurso '{resource_type}' no soportado"}), 400
        
        if resource_id in fhir_store[resource_type]:
            del fhir_store[resource_type][resource_id]
            resource_counter[resource_type] -= 1
            print(f"🗑️ Recurso {resource_type}/{resource_id} eliminado")
            return '', 204
        else:
            return jsonify({"error": f"Recurso {resource_type}/{resource_id} no encontrado"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Endpoint no encontrado",
        "endpoints_disponibles": [
            "/",
            "/fhir",
            "/fhir/metadata", 
            "/fhir/Patient",
            "/fhir/Practitioner",
            "/fhir/Organization"
        ]
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Error interno del servidor"}), 500

if __name__ == '__main__':
    print("\n" + "="*50)
    print("🚀 Iniciando Servidor FHIR Simple para Colombia")
    print("="*50)
    print("📍 URL Base: http://localhost:5000")
    print("🩺 FHIR Base: http://localhost:5000/fhir")
    print("📚 Metadata: http://localhost:5000/fhir/metadata")
    print("👥 Pacientes: http://localhost:5000/fhir/Patient")
    print("👨‍⚕️ Profesionales: http://localhost:5000/fhir/Practitioner")
    print("\n💡 Comandos de prueba:")
    print("   curl http://localhost:5000/fhir/metadata")
    print("   curl -X POST -H 'Content-Type: application/fhir+json' \\")
    print("        -d @fhir_mapping/Patient.json \\")
    print("        http://localhost:5000/fhir/Patient")
    print("\n🛑 Presiona Ctrl+C para detener el servidor")
    print("="*50 + "\n")
    
    # Instalar Flask si no está instalado
    try:
        app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)
    except ImportError:
        print("❌ Flask no está instalado. Ejecuta: pip install flask")
    except KeyboardInterrupt:
        print("\n👋 Servidor FHIR detenido. ¡Hasta luego!")