/**
* Name: Eyetracking
* Based on the internal empty template. 
* Author: flori
* Tags: 
*/


model Eyetracking

global {
    // Global variables related to the Management units	
    file easybuildings <- file('../includes/Easy_buildings_json.geojson'); 
    file easyroad <- file('../includes/qgis_easypath.geojson'); 
    file difficultbuildings <- file('../includes/difficult_buildings_json.geojson'); 
    file difficultroad <- file('../includes/difficult_path_json.geojson'); 
	
    //definition of the environment size from the shapefile. 
    //Note that is possible to define it from several files by using: geometry shape <- envelope(envelope(file1) + envelope(file2) + ...);
    geometry shape <- envelope(difficultroad);
	geometry easy <- easyroad;
	geometry difficult <- difficultroad;
    init {
	//Creation of elementOfNewYork agents from the shapefile (and reading some of the shapefile attributes)
	create EasyBuildings from: easybuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))] ;
    create EasyRoad from: easyroad 
	    with: [elementId::int(read('OBJECTID')), elementHeight::int(read('height')), elementColor::string(read('attrForGama'))] ;
    create DifficultBuildings from: difficultbuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))] ;
    create DifficultRoad from: difficultroad 
	    with: [elementId::int(read('OBJECTID')), elementHeight::int(read('height')), elementColor::string(read('attrForGama'))] ;
    
    
    
    
    
    create cyclist number:1 {
    	location <- any_location_in(difficult);
    	
    	
    	}
    }
}
species EasyRoad{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(0,255,0);}
}	
	
species EasyBuildings{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(0,255,0) depth: elementHeight *6;} 
}	
species DifficultRoad{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(255,0,0);}
}		


species DifficultBuildings{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(255,0,0) depth: elementHeight *6;} 
}	
species cyclist skills:[moving]{
	geometry target_point;
	init{
		 location <- any_location_in(shape);
		 // Define a target point for the cyclist to move to
        target_point <- one_of(shape).location; // Move to the location of one of the Road agents 
	}
	reflex move_to_target {
		do wander speed:2 bounds: difficult;
    }
    reflex stress{
    	
    }
    
    
    aspect default {
	// Cyclist is drawn as a 
		draw circle(7) color: #black;
	
	}
    
}
experiment main type: gui {		
    output {
	display HowToUseOpenStreetMap type:opengl {
	   species EasyBuildings aspect: basic ; 
	   species EasyRoad aspect: basic;
	   species DifficultRoad aspect: basic;
	   species DifficultBuildings aspect: basic;
	   species cyclist aspect: default;
	}
    }
}

