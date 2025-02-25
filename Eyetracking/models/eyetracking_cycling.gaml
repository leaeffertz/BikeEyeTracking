/**
* Name: Eyetracking bicycle interactions
* Author: Florian Winkler, Martin Moser, Lea Effertz
* Description: A model which shows how the interactions with other traffic participants affect a cyclists perception area, point of view and stress level.
* Based on the Simple Traffic Model and the concept of interaction of Luuk's model. 
* Tags:  
*/

model eyetracking_cycling

global {
	
//// initialize environment-data ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	graph network;
	
	file road_diff_nodes <- file("../includes/difficult_route_osm_nodes.geojson");
	file road_diff_edges <- file("../includes/difficult_route_osm_edges.geojson");
	file difficultbuildings <- file("../includes/difficult_4326.geojson");
	
	file road_easy_nodes <- file("../includes/easy_route_osm_nodes.geojson");
	file road_easy_edges <- file("../includes/easy_route_osm_edges.geojson");
	file easybuildings <- file('../includes/easy_4326.geojson');
	
	//set the GAMA coordinate reference system using the one of the building_file (Lambert zone II).
	geometry shape <- envelope(road_diff_edges);
	
	//initialize list to track the participants' parameters
	list<bool> stress_list <- [];
    list<int> speed_list <- [];
    
    //default values for parameters
    int people_nb <- 50;
    float people_speed <- 10.0;
    float part_speed <- 10.0;
    float average;
    float summe;
    float count;
//////// Initialisation ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	init {
		// Create graph from data for both the easy and difficult route
		create road from: road_diff_edges{
			// Create another road in the opposite direction
			create road{
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				linked_road <- myself;
				myself.linked_road <- self;
			}
		}
		create intersection from: road_diff_nodes;
		create DifficultBuildings from: difficultbuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	    create road from: road_easy_edges{
			// Create another road in the opposite direction
			create road {
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				linked_road <- myself;
				myself.linked_road <- self;
			}
		}
	    
		create intersection from: road_easy_nodes;
		create EasyBuildings from: easybuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	    network <- as_driving_graph(road, intersection);
	    
	    // transform coordinate system
		point poi_location <- first(road).location; //location of the first building in the GAMA reference system
		point poi_location_WGS84 <- CRS_transform(poi_location, "EPSG:4326").location; //project the point to WGS84 CRS
		point poi_location_UTM31N <- CRS_transform(poi_location, "EPSG:32631").location; //project the point to UMT 31N CRS
		write "POI location - GAMA coordinates: " + poi_location + "\nWGS84: " + poi_location_WGS84 + "\nUTM 31N: " + poi_location_UTM31N;
		
		// create agents
		create cyclist number: 1 with: (location: one_of(intersection).location);
		create people number: people_nb with: [location::any_location_in(one_of(road))];
	}
}
/////// specifiy environment species ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species intersection skills: [intersection_skill] ;

species road skills: [road_skill] {
	int num_lanes <- 2;
	
	aspect default {
		draw shape color: #gray border: #black;
	}
}

species DifficultBuildings{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(255,0,0) depth: elementHeight *6;} 
}

species EasyBuildings{
    int elementId;
    int elementHeight;
    string elementColor;
	
    aspect basic{
	draw shape color: rgb(0,255,0) depth: elementHeight *6;} 
}	

/////// specify agent species //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species cyclist skills: [driving] {
	geometry action_area <- circle(part_speed) intersection cone(0, 90);
	geometry perception_area <- circle(part_speed) intersection cone(0, 214);
	//geometry sight_line <- line([self.location, current_road])intersection circle(speed);
	float perception_angle;
	float perception_radius;
	
	// parameters
	bool stress <- false; //further research needed, GENDER DIFFERENCES!!!, Stressauslöser nur bei seh r nahem Kontakt, bei crash etc, binär
	
	rgb color <- #red;
	init {
		vehicle_length <- 1 #m;
		max_acceleration <- 3.5;
		current_lane <- 0;
	}
	
	// routing
	reflex select_next_path when: current_path = nil {
		// A path that forms a cycle
		do compute_path graph: network target: one_of(intersection);
		write speed_list;
		average <- mean(speed_list);
		summe <- sum(speed_list);
		count <- length(speed_list); // var0 equals 5 
		write "COUNT" + count;
	}
	
	reflex commute when: current_path != nil {
		do drive;
	}
	aspect base {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
	}
	

	//reflex move {
	//The operator goto is a built-in operator derivated from the moving skill, moving the agent from its location to its target, 
	//   restricted by the on variable, with the speed and returning the path followed
		//my_path <- goto(on: network, target: target, speed: 10.0, return_path: true);
		
		//If the agent arrived to its target location, then it choose randomly an other target on the road
		//if (target = location) {
			//target <- target + 0.009;//any_location_in(one_of (road)) ;
			//write "target is" + target;	
		//} 
		
	
	//Scenario A: There are no other traffic participants in the area, that affect the cyclist
	
	//Scenario B: There is another traffic participant or obsatcle in the perception area of the cyclist.
		
		
	//}
    
    //record parameters to list for each timestep
    reflex report {
    	add stress to: stress_list;
    	add part_speed to: speed_list;
    }
    
    reflex update_actionArea {
		action_area <- circle(part_speed + 10) intersection cone(heading - 45, heading + 45);
		//? add 
		perception_area <- circle(30) intersection cone(heading - 20, heading + 20);
		
		//sight_line <- line([self.location, current_road])intersection circle(speed + 20);
	}
	
	action stress_change{
    	stress <- true;
    }
    
    action speed_change {
    	part_speed <- 4.0;
    }
    
    action change_perception{
    	perception_area <- circle(15) intersection cone(heading - 53, heading + 53);
    }
    
//    action overtake{
//    	write "before:" + current_lane;
//    	
//    	current_lane <- current_lane + 1;
//    	write "after:" + current_lane;
//    }
	
	// visualisation	
	aspect default {
		draw circle(5.0) color: color rotate: heading + 90 border: #black;
	}
	
	aspect action_area {
		draw self.action_area color: #grey;
	}
	
	aspect perception_area {
		draw self.perception_area color: #goldenrod;
	}
	
//	aspect sight_line {
//		draw self.sight_line color: #blue ;
//	}
		

}

species people skills: [driving] {
	// parameters
	rgb color <- rnd_color(255);
	init {
		vehicle_length <- 1 #m;
		max_acceleration <- 3.5;
	}
	
	// routing
	reflex select_next_path when: current_path = nil {
		// A path that forms a cycle
		do compute_path graph: network target: one_of(intersection);
	}
	reflex commute when: current_path != nil {
		do drive;
	}


	// cause stress to the participant
	reflex stress_participant{
		ask cyclist at_distance (30){
			do action: speed_change;
			do action: stress_change;
			do action: change_perception;
		}
//		ask cyclist at_distance (1){
//			do action: overtake;
//		}
	}
	
	// visualisation
	aspect default {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
	}

}

////////// experiment visualisation ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

experiment difficult type: gui {
	parameter "Number of traffic participants" var: people_nb category:"Experiment parameters";
	parameter "Participants' speed" var: part_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	parameter "Others' speed" var: people_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	
	output {
		layout #split;
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:action_area transparency: 0.5;
	   		species cyclist aspect:perception_area transparency: 0.5;
	   		//species cyclist aspect: sight_line;
			species road;
			species people;
			species DifficultBuildings aspect: basic;
		}
		display map_3D background: #white {
			chart "biomass" type: series {
				data "Speed" value: average color: #green;
				data "sum" value: summe color: #red;
				data "Count" value: count color: #yellow;
				}
		
	}
		
	}

}

experiment easy type: gui {
	parameter "Number of traffic participants" var: people_nb category:"Experiment parameters";
	parameter "Participants' speed" var: part_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	parameter "Others' speed" var: people_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	
	output {
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:action_area transparency: 0.5;
	   		species cyclist aspect:perception_area transparency: 0.5;
	   		//species cyclist aspect: sight_line;
			species road;
			species people;
			species EasyBuildings aspect: basic ; 
		}

	}

}
