#!/bin/bash
# generate-graph.sh - Generate knowledge graph from extracted entities and relationships
# This script generates a JSON-LD knowledge graph from the extracted entities and relationships

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Input and output directories
ENTITIES_DIR="$ROOT_DIR/docs/knowledge-graph/entities"
RELATIONSHIPS_DIR="$ROOT_DIR/docs/knowledge-graph/relationships"
VISUALIZATIONS_DIR="$ROOT_DIR/docs/knowledge-graph/visualizations"

# Output files
GRAPH_FILE="$ROOT_DIR/docs/knowledge-graph/graph.json"
GRAPH_DIR="$(dirname "$GRAPH_FILE")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if required tools are installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please install it to process JSON files.${NC}"
        echo "You can install it with: sudo apt-get install jq"
        exit 1
    fi
    
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}Error: yq is not installed. Please install it to process YAML files.${NC}"
        echo "You can install it with: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
        exit 1
    fi
    
    if ! command -v dot &> /dev/null; then
        echo -e "${YELLOW}Warning: Graphviz (dot) is not installed. Visualizations will not be generated.${NC}"
        echo "You can install it with: sudo apt-get install graphviz"
    fi
}

# Create the output directories if they don't exist
create_output_directories() {
    if [[ ! -d "$GRAPH_DIR" ]]; then
        mkdir -p "$GRAPH_DIR"
        echo "Created knowledge graph directory: $GRAPH_DIR"
    fi
    
    if [[ ! -d "$VISUALIZATIONS_DIR" ]]; then
        mkdir -p "$VISUALIZATIONS_DIR"
        echo "Created visualizations directory: $VISUALIZATIONS_DIR"
    fi
}

# Generate the knowledge graph
generate_graph() {
    echo "Generating knowledge graph..."
    
    # Create the base graph structure
    cat > "$GRAPH_FILE" << EOF
{
  "@context": {
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "llm": "http://local-llm-stack.org/ontology#",
    "name": "rdfs:label",
    "description": "rdfs:comment",
    "type": "rdf:type",
    "component": "llm:Component",
    "container": "llm:Container",
    "script": "llm:Script",
    "library": "llm:Library",
    "module": "llm:Module",
    "relationship": "llm:Relationship",
    "interface": "llm:Interface",
    "api": "llm:API",
    "cli": "llm:CLI",
    "function": "llm:Function",
    "variable": "llm:Variable",
    "parameter": "llm:Parameter",
    "configParam": "llm:ConfigParam",
    "service": "llm:Service",
    "dataFlow": "llm:DataFlow",
    "source": "llm:source",
    "target": "llm:target",
    "dependsOn": "llm:dependsOn",
    "calls": "llm:calls",
    "imports": "llm:imports",
    "configures": "llm:configures",
    "defines": "llm:defines",
    "uses": "llm:uses",
    "providesServiceTo": "llm:providesServiceTo",
    "startupDependency": "llm:startupDependency",
    "runtimeDependency": "llm:runtimeDependency",
    "configurationDependency": "llm:configurationDependency",
    "exposes": "llm:exposes",
    "implements": "llm:implements",
    "hasFunction": "llm:hasFunction",
    "hasParameter": "llm:hasParameter",
    "hasStep": "llm:hasStep",
    "hasEndpoint": "llm:hasEndpoint",
    "hasCommand": "llm:hasCommand",
    "filePath": "llm:filePath",
    "lineNumber": "llm:lineNumber",
    "signature": "llm:signature",
    "returnType": "llm:returnType",
    "parameterType": "llm:parameterType",
    "defaultValue": "llm:defaultValue",
    "required": "llm:required"
  },
  "@graph": []
}
EOF
    
    # Add entities to the graph
    echo "Adding entities to the graph..."
    
    # Add components
    if [[ -f "$ENTITIES_DIR/components.json" ]]; then
        echo "Adding components..."
        local components=$(jq -c '.[]' "$ENTITIES_DIR/components.json")
        
        for component in $components; do
            # Add component to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$component" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local component_name=$(echo "$component" | jq -r '.name')
            echo "Added component: $component_name"
        done
    fi
    
    # Add functions
    if [[ -f "$ENTITIES_DIR/functions.json" ]]; then
        echo "Adding functions..."
        local functions=$(jq -c '.[]' "$ENTITIES_DIR/functions.json")
        
        for function in $functions; do
            # Add function to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$function" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local function_name=$(echo "$function" | jq -r '.name')
            echo "Added function: $function_name"
        done
    fi
    
    # Add variables
    if [[ -f "$ENTITIES_DIR/variables.json" ]]; then
        echo "Adding variables..."
        local variables=$(jq -c '.[]' "$ENTITIES_DIR/variables.json")
        
        for variable in $variables; do
            # Add variable to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$variable" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local variable_name=$(echo "$variable" | jq -r '.name')
            echo "Added variable: $variable_name"
        done
    fi
    
    # Add configuration parameters
    if [[ -f "$ENTITIES_DIR/config_params.json" ]]; then
        echo "Adding configuration parameters..."
        local config_params=$(jq -c '.[]' "$ENTITIES_DIR/config_params.json")
        
        for config_param in $config_params; do
            # Add configuration parameter to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$config_param" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local param_name=$(echo "$config_param" | jq -r '.name')
            echo "Added configuration parameter: $param_name"
        done
    fi
    
    # Add services
    if [[ -f "$ENTITIES_DIR/services.json" ]]; then
        echo "Adding services..."
        local services=$(jq -c '.[]' "$ENTITIES_DIR/services.json")
        
        for service in $services; do
            # Add service to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$service" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local service_name=$(echo "$service" | jq -r '.name')
            echo "Added service: $service_name"
        done
    fi
    
    # Add relationships to the graph
    echo "Adding relationships to the graph..."
    
    # Add function calls
    if [[ -f "$RELATIONSHIPS_DIR/function_calls.json" ]]; then
        echo "Adding function calls..."
        local function_calls=$(jq -c '.[]' "$RELATIONSHIPS_DIR/function_calls.json")
        
        for function_call in $function_calls; do
            # Add function call to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$function_call" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local call_name=$(echo "$function_call" | jq -r '.name')
            echo "Added function call: $call_name"
        done
    fi
    
    # Add component dependencies
    if [[ -f "$RELATIONSHIPS_DIR/component_dependencies.json" ]]; then
        echo "Adding component dependencies..."
        local component_dependencies=$(jq -c '.[]' "$RELATIONSHIPS_DIR/component_dependencies.json")
        
        for component_dependency in $component_dependencies; do
            # Add component dependency to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$component_dependency" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local dependency_name=$(echo "$component_dependency" | jq -r '.name')
            echo "Added component dependency: $dependency_name"
        done
    fi
    
    # Add configuration dependencies
    if [[ -f "$RELATIONSHIPS_DIR/config_dependencies.json" ]]; then
        echo "Adding configuration dependencies..."
        local config_dependencies=$(jq -c '.[]' "$RELATIONSHIPS_DIR/config_dependencies.json")
        
        for config_dependency in $config_dependencies; do
            # Add configuration dependency to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$config_dependency" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local dependency_name=$(echo "$config_dependency" | jq -r '.name')
            echo "Added configuration dependency: $dependency_name"
        done
    fi
    
    # Add imports
    if [[ -f "$RELATIONSHIPS_DIR/imports.json" ]]; then
        echo "Adding imports..."
        local imports=$(jq -c '.[]' "$RELATIONSHIPS_DIR/imports.json")
        
        for import in $imports; do
            # Add import to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$import" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local import_name=$(echo "$import" | jq -r '.name')
            echo "Added import: $import_name"
        done
    fi
    
    # Add data flows
    if [[ -f "$RELATIONSHIPS_DIR/data_flows.json" ]]; then
        echo "Adding data flows..."
        local data_flows=$(jq -c '.[]' "$RELATIONSHIPS_DIR/data_flows.json")
        
        for data_flow in $data_flows; do
            # Add data flow to the graph
            local temp_file=$(mktemp)
            jq --argjson node "$data_flow" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$temp_file" && mv "$temp_file" "$GRAPH_FILE"
            
            local flow_name=$(echo "$data_flow" | jq -r '.name')
            echo "Added data flow: $flow_name"
        done
    fi
    
    # Add interfaces from YAML documentation
    echo "Adding interfaces from YAML documentation..."
    local interfaces_file="$ROOT_DIR/docs/system/interfaces.yaml"
    
    if [[ -f "$interfaces_file" ]]; then
        # Add API interfaces
        if yq eval '.api_interfaces' "$interfaces_file" > /dev/null 2>&1; then
            echo "Adding API interfaces..."
            local api_count=$(yq eval '.api_interfaces | length' "$interfaces_file")
            
            for ((i=0; i<api_count; i++)); do
                local component=$(yq eval ".api_interfaces[$i].component" "$interfaces_file")
                local interface_type=$(yq eval ".api_interfaces[$i].interface_type" "$interfaces_file")
                local base_url=$(yq eval ".api_interfaces[$i].base_url" "$interfaces_file")
                
                # Create API interface node
                local api_node="{
                    \"@id\": \"llm:${component}_api\",
                    \"@type\": \"llm:API\",
                    \"name\": \"${component} API\",
                    \"description\": \"API interface for ${component}\",
                    \"baseUrl\": \"${base_url}\"
                }"
                
                # Add API interface to the graph
                jq --argjson node "$api_node" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$GRAPH_FILE.tmp" && mv "$GRAPH_FILE.tmp" "$GRAPH_FILE"
                
                # Add relationship between component and API
                local api_relationship="{
                    \"@id\": \"llm:${component}\",
                    \"exposes\": {\"@id\": \"llm:${component}_api\"}
                }"
                
                # Add API relationship to the graph
                jq --argjson node "$api_relationship" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$GRAPH_FILE.tmp" && mv "$GRAPH_FILE.tmp" "$GRAPH_FILE"
                
                echo "Added API interface for: $component"
            done
        fi
        
        # Add CLI interfaces
        if yq eval '.cli_interfaces' "$interfaces_file" > /dev/null 2>&1; then
            echo "Adding CLI interfaces..."
            local cli_count=$(yq eval '.cli_interfaces | length' "$interfaces_file")
            
            for ((i=0; i<cli_count; i++)); do
                local component=$(yq eval ".cli_interfaces[$i].component" "$interfaces_file")
                
                # Create CLI interface node
                local cli_node="{
                    \"@id\": \"llm:${component}_cli\",
                    \"@type\": \"llm:CLI\",
                    \"name\": \"${component} CLI\",
                    \"description\": \"CLI interface for ${component}\"
                }"
                
                # Add CLI interface to the graph
                jq --argjson node "$cli_node" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$GRAPH_FILE.tmp" && mv "$GRAPH_FILE.tmp" "$GRAPH_FILE"
                
                # Add relationship between component and CLI
                local cli_relationship="{
                    \"@id\": \"llm:${component}\",
                    \"exposes\": {\"@id\": \"llm:${component}_cli\"}
                }"
                
                # Add CLI relationship to the graph
                jq --argjson node "$cli_relationship" '.["@graph"] += [$node]' "$GRAPH_FILE" > "$GRAPH_FILE.tmp" && mv "$GRAPH_FILE.tmp" "$GRAPH_FILE"
                
                echo "Added CLI interface for: $component"
            done
        fi
    fi
    
    echo -e "${GREEN}Knowledge graph generated successfully: $GRAPH_FILE${NC}"
    return 0
}

# Generate visualizations of the knowledge graph
generate_visualizations() {
    echo "Generating visualizations..."
    
    # Check if Graphviz is installed
    if ! command -v dot &> /dev/null; then
        echo -e "${YELLOW}Warning: Graphviz (dot) is not installed. Visualizations will not be generated.${NC}"
        return 1
    fi
    
    # Generate component dependency visualization
    echo "Generating component dependency visualization..."
    local component_dot_file="$VISUALIZATIONS_DIR/component_dependencies.dot"
    local component_svg_file="$VISUALIZATIONS_DIR/component_dependencies.svg"
    
    # Create DOT file header
    cat > "$component_dot_file" << EOF
digraph ComponentDependencies {
  rankdir=LR;
  node [shape=box, style=filled, fillcolor=lightblue];
  edge [color=black, fontcolor=black];
  
EOF
    
    # Add components and dependencies
    if [[ -f "$ENTITIES_DIR/components.json" ]]; then
        local components=$(jq -r '.[] | .name' "$ENTITIES_DIR/components.json")
        
        # Add component nodes
        for component in $components; do
            echo "  \"$component\" [label=\"$component\"];" >> "$component_dot_file"
        done
        
        # Add dependency edges
        if [[ -f "$RELATIONSHIPS_DIR/component_dependencies.json" ]]; then
            local dependencies=$(jq -r '.[] | .source + " -> " + .target' "$RELATIONSHIPS_DIR/component_dependencies.json" | sed 's/llm://g')
            
            for dependency in $dependencies; do
                echo "  $dependency [label=\"depends on\"];" >> "$component_dot_file"
            done
        fi
    fi
    
    # Close DOT file
    echo "}" >> "$component_dot_file"
    
    # Generate SVG
    dot -Tsvg "$component_dot_file" -o "$component_svg_file"
    
    # Generate function call visualization
    echo "Generating function call visualization..."
    local function_dot_file="$VISUALIZATIONS_DIR/function_calls.dot"
    local function_svg_file="$VISUALIZATIONS_DIR/function_calls.svg"
    
    # Create DOT file header
    cat > "$function_dot_file" << EOF
digraph FunctionCalls {
  rankdir=LR;
  node [shape=ellipse, style=filled, fillcolor=lightgreen];
  edge [color=black, fontcolor=black];
  
EOF
    
    # Add functions and calls
    if [[ -f "$ENTITIES_DIR/functions.json" ]]; then
        local functions=$(jq -r '.[] | .name' "$ENTITIES_DIR/functions.json")
        
        # Add function nodes
        for function in $functions; do
            echo "  \"$function\" [label=\"$function\"];" >> "$function_dot_file"
        done
        
        # Add call edges
        if [[ -f "$RELATIONSHIPS_DIR/function_calls.json" ]]; then
            local calls=$(jq -r '.[] | .source + " -> " + .target' "$RELATIONSHIPS_DIR/function_calls.json" | sed 's/llm://g')
            
            for call in $calls; do
                echo "  $call [label=\"calls\"];" >> "$function_dot_file"
            done
        fi
    fi
    
    # Close DOT file
    echo "}" >> "$function_dot_file"
    
    # Generate SVG
    dot -Tsvg "$function_dot_file" -o "$function_svg_file"
    
    # Generate data flow visualization
    echo "Generating data flow visualization..."
    local dataflow_dot_file="$VISUALIZATIONS_DIR/data_flows.dot"
    local dataflow_svg_file="$VISUALIZATIONS_DIR/data_flows.svg"
    
    # Create DOT file header
    cat > "$dataflow_dot_file" << EOF
digraph DataFlows {
  rankdir=LR;
  node [shape=box, style=filled, fillcolor=lightyellow];
  edge [color=black, fontcolor=black];
  
EOF
    
    # Add data flows
    if [[ -f "$RELATIONSHIPS_DIR/data_flows.json" ]]; then
        local flows=$(jq -r '.[] | .source + " -> " + .target + " [label=\"" + .data + "\"];"' "$RELATIONSHIPS_DIR/data_flows.json" | sed 's/llm://g')
        
        # Add flow edges
        for flow in $flows; do
            echo "  $flow" >> "$dataflow_dot_file"
        done
    fi
    
    # Close DOT file
    echo "}" >> "$dataflow_dot_file"
    
    # Generate SVG
    dot -Tsvg "$dataflow_dot_file" -o "$dataflow_svg_file"
    
    echo -e "${GREEN}Visualizations generated successfully!${NC}"
    return 0
}

# Main function
main() {
    echo "Starting knowledge graph generation..."
    
    # Check dependencies
    check_dependencies
    
    # Create the output directories
    create_output_directories
    
    # Extract entities if they don't exist
    if [[ ! -f "$ENTITIES_DIR/components.json" || ! -f "$ENTITIES_DIR/functions.json" ]]; then
        echo "Entities not found. Extracting entities..."
        "$ROOT_DIR/tools/entity-extraction/extract-entities.sh"
    fi
    
    # Map relationships if they don't exist
    if [[ ! -f "$RELATIONSHIPS_DIR/function_calls.json" || ! -f "$RELATIONSHIPS_DIR/component_dependencies.json" ]]; then
        echo "Relationships not found. Mapping relationships..."
        "$ROOT_DIR/tools/relationship-mapping/map-relationships.sh"
    fi
    
    # Generate the knowledge graph
    generate_graph
    
    # Generate visualizations
    generate_visualizations
    
    echo -e "${GREEN}Knowledge graph generation completed successfully!${NC}"
    return 0
}

# Run the main function
main