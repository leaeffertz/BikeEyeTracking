/**
* Name: Eyetracking bicycle interactions
* Author: Florian Winkler, Martin Moser, Lea Effertz
* Description: A model which shows how the interactions with other traffic participants affect a cyclists perception area, point of view and stress level.
* Based on the Simple Traffic Model and the concept of interaction of Luuk's model. 
* Tags:  
*/
model From_GAMA_CRS

global {
	graph network;
	 
	
	file road_diff_nodes <- file("../includes/difficult_route_osm_nodes.geojson");
	file road_diff_edges <- file("../includes/difficult_route_osm_edges.geojson");
	file difficultbuildings <- file("../includes/difficult_4326.geojson");
	
	file road_easy_nodes <- file("../includes/easy_route_osm_nodes.geojson");
	file road_easy_edges <- file("../includes/easy_route_osm_edges.geojson");
	file easybuildings <- file('../includes/easy_4326.geojson');
	
	//set the GAMA coordinate reference system using the one of the building_file (Lambert zone II).
	geometry shape <- envelope(road_diff_edges);
	
	list<int> stress_list <- [];
    list<int> speed_list <- [];
	
	init {
		create road from: road_diff_edges;
		create intersection from: road_diff_nodes;
		
		create DifficultBuildings from: difficultbuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	    create road from: road_easy_edges;
		create intersection from: road_easy_nodes;
		create EasyBuildings from: easybuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
		point poi_location <- first(road).location; //location of the first building in the GAMA reference system
		create people number: 50 with: [location::any_location_in(one_of(road))];
		point poi_location_WGS84 <- CRS_transform(poi_location, "EPSG:4326").location; //project the point to WGS84 CRS
		point poi_location_UTM31N <- CRS_transform(poi_location, "EPSG:32631").location; //project the point to UMT 31N CRS
		write "POI location - GAMA coordinates: " + poi_location + "\nWGS84: " + poi_location_WGS84 + "\nUTM 31N: " + poi_location_UTM31N;
		network <- directed(as_edge_graph(road));

		create cyclist number: 1 {
		//with: [location::any_location_in(one_of(road))];
			target <- any_location_in(one_of(road));
			location <- any_location_in(one_of(road));
		}
		
	}
}

species intersection skills: [intersection_skill] ;

species road {
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

species cyclist skills: [driving] {
	rgb color <- #red;
	point target;
	path my_path;
	
	geometry action_area <- circle(speed) intersection cone(0, 90);
	geometry perception_area <- circle(speed) intersection cone(0, 214);
	geometry sight_line <- line([self.location, current_road])intersection circle(speed);
	float perception_angle;
	float perception_radius;
	
	float speed <- 5.0;
	bool stress <- false; //further research needed, GENDER DIFFERENCES!!!, Stressauslöser nur bei seh r nahem Kontakt, bei crash etc, binär

	reflex move {
	//The operator goto is a built-in operator derivated from the moving skill, moving the agent from its location to its target, 
	//   restricted by the on variable, with the speed and returning the path followed
		my_path <- goto(on: network, target: target, speed: 10.0, return_path: true);
		
		//If the agent arrived to its target location, then it choose randomly an other target on the road
		if (target = location) {
			target <- target + 0.009;//any_location_in(one_of (road)) ;
			write "target is" + target;	
		} 
		
	
	//Scenario A: There are no other traffic participants in the area, that affect the cyclist
	
	//Scenario B: There is another traffic participant or obsatcle in the perception area of the cyclist.
		
		
	}
		
	action stress_change{
    	stress <- true;
    }
    
    action speed_change {
    	speed <- 4.0;
    }
    
    action change_perception{
    	perception_area <- circle(15) intersection cone(heading - 53, heading + 53);
    }
    
    action overtake{
    	current_lane <- 1;
    	write current_lane;
    }
    
    
    reflex report {
    	add stress to: stress_list;
    	//write "stress: " + stress_list;
    	add speed to: speed_list;
    	//write "speed: " + speed_list;
    }
    
    reflex update_actionArea {
		action_area <- circle(speed + 10) intersection cone(heading - 45, heading + 45);
		//? add 
		perception_area <- circle(30) intersection cone(heading - 20, heading + 20);
		
		sight_line <- line([self.location, current_road])intersection circle(speed + 20);
	}
		
	aspect default {
		draw circle(5.0) color: color border: #black;
	}
	
	aspect action_area {
		draw self.action_area color: #grey;
	}
	
	aspect perception_area {
		draw self.perception_area color: #goldenrod;
	}
	
	aspect sight_line {
		draw self.sight_line color: #blue ;
	}
		

}

species people skills: [moving] {
	rgb color <- rnd_color(255);

	aspect default {
		draw circle(1.0) color: color border: #black;
	}

	reflex move {
		do wander on: network;
	}
	
	reflex stress_participant{
		ask cyclist at_distance (30){
			do action: speed_change;
			do action: stress_change;
			do action: change_perception;
			write "I interacted!";
		}
		ask cyclist at_distance (5){
			do action: overtake;
		}
	}

}

experiment difficult type: gui {
	output {
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:action_area transparency: 0.5;
	   		species cyclist aspect:perception_area transparency: 0.5;
	   		//species cyclist aspect: sight_line;
			species road;
			species people;
			species DifficultBuildings aspect: basic;
		}

	}

}

experiment easy type: gui {
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
