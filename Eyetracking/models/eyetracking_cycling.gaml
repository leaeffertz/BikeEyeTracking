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
	file road_diff_edges <- file("../includes/difficult_route_osm_edges2.geojson");
	file difficultbuildings <- file("../includes/difficult_4326.geojson");
	
	file road_easy_nodes <- file("../includes/easy_route_osm_nodes.geojson");
	file road_easy_edges <- file("../includes/easy_route_osm_edges2.geojson");
	file easybuildings <- file('../includes/easy_4326.geojson');
	
	//file polygon_stats_objects <- file("../includes/polygons_object_counts.geojson");
	
	//set the GAMA coordinate reference system using the one of the building_file (Lambert zone II).
	geometry shape <- envelope(road_diff_edges);
	
	//initialize list to track the participants' parameters
	list<bool> stress_list <- [];
    list<int> speed_list <- [];
    list<float> heart_rate_list <- [];
    list<geometry> out_intersections;
    
    //default values for parameters
    int people_nb <- 50;
    float people_speed <- 10.0;
    float part_speed <- 10.0;
    float stress;
    float heart_rate <- 6.5;
    int stressindicator;
    list<int> traffic_count <- [];
    int alert_duration <-5;
    int time_since_alert;
    list <int> stresscount;
    
//////// Initialisation ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	init {
		// Create graph from data for both the easy and difficult route
		create road from: road_diff_edges{
			// Create another road in the opposite direction
			create road{
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				MOS_score_mean <- myself.MOS_score_mean;
				MOS_score_sum <- myself.MOS_score_sum;
				speed_kmh_avg <- myself.speed_kmh_avg;
				speed_kmh_max <- myself.speed_kmh_max;
				altitude_avg <- myself.altitude_avg;
				EDA_avg <- myself.EDA_avg;
				ST_avg <- myself.ST_avg;
				blink_dur_avg_ms <- myself.blink_dur_avg_ms;
				blink_dur_sum_ms <- myself.blink_dur_sum_ms;
				blink_count <- myself.blink_count;
				pixel_x_avg <- myself.pixel_x_avg;
				pixel_y_avg <- myself.pixel_y_avg;
				azimuth_deg_x <- myself.azimuth_deg_x;
				azimuth_deg_y <- myself.azimuth_deg_y;
				other_road_users_cnt <- myself.other_road_users_cnt;
				other_motor_traffic_cnt <- myself.other_motor_traffic_cnt;
				traffic_sign_cnt <- myself.traffic_sign_cnt;
				linked_road <- myself;
				myself.linked_road <- self;
			}
		}
		
		// "maxspeed": "50", "oneway": false, "reversed": "False", "length": 10.066772343411511, "ref": null, "access": null, "tunnel": null, "bridge": null, "width": null, 
		// "index_right": 350, "polygon_id": 603, "MOS_cnt_sum": 0.0, "MOS_cnt_ratio": 0.0, "MOS/non-MOS": 0.0, "MOS_score_sum": 0.0, "MOS_score_mean": 0.0, "speed_kmh_avg": 16.557999563217162, 
		// "speed_kmh_max": 22.356000137329101, "altitude_avg": 473.77777777777777, "EDA_avg": 0.82758635217604959, "ST_avg": 0.0097472234254003757, "blink_dur_avg_ms": 262.22222222222223, 
		// "blink_dur_sum_ms": 2360, "blink_count": 9, "pixel_x_avg": 841.39558024691348, 
		// "pixel_y_avg": 395.68266666666671, "azimuth_deg_x": 3.1942935386677971, "azimuth_deg_y": 3.1942935386677971, 
		// "other_road_users_cnt": 175, "other_motor_traffic_cnt": 138, "traffic_sign_cnt": 50
		
		list<geometry> all_difficult_intersections <- road_diff_nodes.contents;
		write "all_difficult_intersections " + length(all_difficult_intersections);
		list<geometry> all_easy_intersections <- road_easy_nodes.contents;
		write "all_easy_intersections " + length(all_easy_intersections);
		list<geometry> all_intersections <- union(all_difficult_intersections, all_easy_intersections);
		
		write "All intersections combined " + length(all_intersections);
		
		
		create intersection from: road_diff_nodes;
		
		// Get intersections with street_count less than 2, where people / cars could randomly leave
		out_intersections <- intersection where (each.street_count < 2);
		write "Number of intersections with 'street_count' < 2: " + length(out_intersections);
		
		create DifficultBuildings from: difficultbuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	    create road from: road_easy_edges{
			// Create another road in the opposite direction
			create road {
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				MOS_score_mean <- myself.MOS_score_mean;
				MOS_score_sum <- myself.MOS_score_sum;
				speed_kmh_avg <- myself.speed_kmh_avg;
				speed_kmh_max <- myself.speed_kmh_max;
				altitude_avg <- myself.altitude_avg;
				EDA_avg <- myself.EDA_avg;
				ST_avg <- myself.ST_avg;
				blink_dur_avg_ms <- myself.blink_dur_avg_ms;
				blink_dur_sum_ms <- myself.blink_dur_sum_ms;
				blink_count <- myself.blink_count;
				pixel_x_avg <- myself.pixel_x_avg;
				pixel_y_avg <- myself.pixel_y_avg;
				azimuth_deg_x <- myself.azimuth_deg_x;
				azimuth_deg_y <- myself.azimuth_deg_y;
				other_road_users_cnt <- myself.other_road_users_cnt;
				other_motor_traffic_cnt <- myself.other_motor_traffic_cnt;
				traffic_sign_cnt <- myself.traffic_sign_cnt;
				linked_road <- myself;
				myself.linked_road <- self;
			}
		}
		

	    
		create intersection from: road_easy_nodes;
		create EasyBuildings from: easybuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	//    create polygon_areas from: polygon_stats_objects
	//    with: [polygonID::int(read('polygon_id')), other_road_users_cnt::int(read('other_road_users_cnt')), other_motor_traffic_cnt::int(read('other_motor_traffic_cnt')), 
	//   	traffic_sign_cnt::int(read('traffic_sign_cnt')) ];
	    	
	    

//	int polygonID;
//	int other_road_users_cnt;
//	int other_motor_traffic_cnt;
//	int traffic_sign_cnt;
//	
//	float stress_score;
//	int detected_stress;
//	float eda;
	    //create road from: polygon_stats_objects with: [shape::geometry(each)];
	    
	    //map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
	    map<road,float> weights_map <- road as_map (each:: (each.MOS_score_mean));
	    network <- as_driving_graph(road, intersection) with_weights weights_map;
	    
	    
	    // transform coordinate system
		point poi_location <- first(road).location; //location of the first building in the GAMA reference system
		point poi_location_WGS84 <- CRS_transform(poi_location, "EPSG:4326").location; //project the point to WGS84 CRS
		point poi_location_UTM31N <- CRS_transform(poi_location, "EPSG:32631").location; //project the point to UMT 31N CRS
		write "POI location - GAMA coordinates: " + poi_location + "\nWGS84: " + poi_location_WGS84 + "\nUTM 31N: " + poi_location_UTM31N;
		
		// create agents
		create cyclist number: 1 with: (location: one_of(intersection).location);
		create people number: people_nb with: [location::any_location_in(one_of(road))];
		
	}
	
	reflex create_new_person_leaving when: every(10 #cycles) {
		create people number: 1 with: (location: one_of(out_intersections).location);
        }
        
    //reflex remove_dead_agents {
    //    ask my_species where (each.age >= 10) {
    //        do die;
    //    }
}
/////// specifiy environment species ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


species intersection skills: [intersection_skill] {
	bool is_traffic_signal;
	int street_count;
	string highway;
	
	reflex intersection_close{
		// Stop at intersections if it is within 5 meters
		ask cyclist at_distance (5){
			write "Cyclist if 5 meters from next intersection!";
			do action: stop_at_intersection;
			//do action: change_perception;
			//write "I interacted close to an intersection!";
			//do action: stop_at_intersection;
		}
		// Change perception area if 20 meters from intersection
		ask cyclist at_distance (20) {
			do action: change_perception;
		}
	}
		
}

species road skills: [road_skill] {
	int num_lanes <- 2;
	float MOS_score_mean;
	float MOS_score_sum;
	float speed_kmh_avg;
	float speed_kmh_max;
	float altitude_avg;
	float EDA_avg;
	float ST_avg;
	float blink_dur_avg_ms;
	float blink_dur_sum_ms;
	int blink_count;
	float pixel_x_avg;
	float pixel_y_avg;
	float azimuth_deg_x;
	float azimuth_deg_y;
	int other_road_users_cnt;
	int other_motor_traffic_cnt;
	int traffic_sign_cnt;
	
//	int colorValue <- int(255*(MOS_score_mean - 1)) update: int(255*(MOS_score_mean - 1));
//	rgb color <- rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0)  update: rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0) ;
//	
//	aspect base {
//		draw shape color: color border: #black;
//	}

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

species polygon_areas {
	int polygonID;
	int other_road_users_cnt;
	int other_motor_traffic_cnt;
	int traffic_sign_cnt;
	
	float stress_score;
	int detected_stress;
	float eda;
	
    aspect default {
        draw shape color: #lightblue border: #black;
    }
    
    		  // Calculate and set weights for each edge based on polygon intersections
//    loop edge over: road_network.edges {
//            float weight <- 1.0; // Default weight
//            ask polygon_area {
//                if edge intersects self {
//                    // You can customize this weight calculation based on your needs
//                    weight <- weight + 1.0;
//                }
//            }
//            road_network weight_of edge <- weight;
//        }
}

/////// specify agent species //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species cyclist skills: [driving] {
	//geometry action_area <- circle(part_speed) intersection cone(0, 90);
	geometry perception_area <- circle(part_speed) intersection cone(0, 214);
	//geometry sight_line <- line([self.location, current_road])intersection circle(speed);
	
	//float perception_angle;
	//float perception_radius;
	
	// default parameters
	bool stress <- false; //further research needed, GENDER DIFFERENCES!!!, Stressauslöser nur bei seh r nahem Kontakt, bei crash etc, binär
	//float heart_rate <- 65.0;
	float default_speed <- part_speed;
    float default_heart_rate <- heart_rate;

   //	int time_since_alert <-0;
    bool careful <- false;
    
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
	}
	//Scenario A: There are no other traffic participants in the area, that affect the cyclist: 
	//the participants vitals are not affected and stay the default values
	reflex commute when: current_path != nil {
		do drive;
	}
	
	//Stop at intersections action
	 action stop_at_intersection{
    	speed <- 0.0;
    	write "Stopped";
    	//do stop;
    }
	//Scenario B: There is another traffic participant or obsatcle in the perception area of the cyclist:
	// the cyclist is now alerted and the vitals change depending on the number of other people in the perception area of the participant.
	reflex update {
        //count traffic in perception area
        int nearby_count <- length(traffic_count);
        
        write nearby_count;
        if (nearby_count > 0){
            // set default values if there arent other traffic participants
            if (!careful){
                default_speed <- part_speed;
                default_heart_rate <- heart_rate;
                careful <- true;
                time_since_alert <- 0;
               	traffic_count <- [];
            }
            //adjust parameters if there is other traffic
            part_speed <- default_speed * max(0.28, 1 - 0.1 * nearby_count);
            heart_rate <- default_heart_rate * (1 + 0.05 * nearby_count);
            stress <- true;
            traffic_count <- [];
        }else{
            // no other traffic detected, results in reverting the paramters if the duration is reached
            if (careful) {
                time_since_alert <- time_since_alert + 1;
                if (time_since_alert >= alert_duration){
                    part_speed <- default_speed;
                    heart_rate <- default_heart_rate;
                    stress <- false;
                    careful <- false;
                    traffic_count <- [];
                }
            }
        }
    }
    
    
	action update_perception_area {
		perception_area <- circle(part_speed) intersection cone(0, 300);
	}
    
    
//	action update_perception_area (float rad <- nil, float ang <- nil) {
//		// The perception neighborhood is the area in which the cyclist can perceive obstacles and identify temporary targets.
//		// The perception neighborhood has the shape of a cone with given angle that is cut at a given radius.
//		// The radius and angle depend on the speed of the cyclist, unless specified otherwise.
//		// The radius is always equal to twice the speed ("auf halbe sicht fahren"), unless specified otherwise.
//		// The angle decreases linearly between 20 degrees for max speed (6 m/s) and 160 degrees for min speed (3 m/s).
//		// The perception neighborhood points towards the heading of the cyclist.
//		// Obstacles can mask the perception neighborhood shape.
//		if (rad = nil) {
//			self.pn_rad <- self.speed * 2 ;
//		} else {
//			self.pn_rad <- rad ;
//		}
//		if (ang = nil) {
//			self.pn_ang <- -47 * self.speed + 300 ;
//		} else {
//			self.pn_ang <- ang ;
//		}
//		//self.heading <- towards(self.location, self.tmp_target) ; // Note that heading is a built-in property.
//		geometry pn_circle <- circle(self.pn_rad) ;
//		geometry pn_cone <- cone(self.heading - self.pn_ang / 2, self.heading + self.pn_ang / 2) ;
//
//    	self.pn <- (pn_circle intersection pn_cone);
//
//		self.perception_area <- circle(part_speed) intersection cone(0, 300);
//		
//		// If the sightline is blocked by an obstacle, the cyclist will take action to avoid the obstacle.
//		//self.sl <- 	line([self.location, self.tmp_target]) intersection circle(self.pn_rad) ;
//	}
	
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
	//}
    
    //record parameters to list for each timestep
    reflex report {
    	add stress to: stress_list;
    	add part_speed to: speed_list;
    	add heart_rate to: heart_rate_list;
    	stressindicator <- 0;
    	if stress {
					stressindicator <- 6;
					add stressindicator to: stresscount;
				}
		
		
    	write "stress: " + stress_list;
    	write "speed: "+ speed_list;
    	write "heart_rate: " + heart_rate_list;
    	write "number of people: " + traffic_count;
    }
    
    
    reflex update_actionArea {
		//action_area <- circle(part_speed + 10) intersection cone(heading - 45, heading + 45);
		//? add 
		perception_area <- circle(30) intersection cone(heading - 20, heading + 20);
		
		//sight_line <- line([self.location, current_road])intersection circle(speed + 20);
	}
	
//	action heart_change{
//		heart_rate <- heart_rate * 1.2;
//	}
//	
//	action stress_change{
//    	stress <- true;
//    }
//    
//    action speed_change {
//    	part_speed <- part_speed * 0.5;
//    }
    
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
		max_acceleration <- 0.71;
		right_side_driving <- true;
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
//			do action: speed_change;
//			do action: stress_change;
			do action: change_perception;
			add 1 to: traffic_count;
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
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:action_area transparency: 0.5;
	   		species cyclist aspect:perception_area transparency: 0.5;
	   		//species cyclist aspect: sight_line;
			species road;
			species people;
			species DifficultBuildings aspect: basic;
			//species polygon_areas aspect: default;
		}
		display map_3D background: #white {
			chart "biomass" type: series {
				data "Stress" value: stressindicator color: #red;
				data "Part_speed" value: part_speed color: #green;
				data "Heart_rate" value: heart_rate color: #orange;
				data "Heart_rate_avg" value: mean(heart_rate_list) color: #blue;
				//data "Stresscount" value: length(stresscount) color: #blue;
				//data "Timeduration" value: time_since_alert color: #blue;
				}
		
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
			//species polygon_areas aspect: default;
		}
		display map_3D background: #white {
			chart "biomass" type: series {
				data "Stress" value: stressindicator color: #red;
				data "Part_speed" value: part_speed color: #green;
				data "Heart_rate" value: heart_rate color: #orange;
				data "Heart_rate_avg" value: mean(heart_rate_list) color: #blue;
				//data "Stresscount" value: length(stresscount) color: #blue;
				//data "Timeduration" value: time_since_alert color: #blue;
				}
		
	}

	}

}
