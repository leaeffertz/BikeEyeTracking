/**
* Name: Eyetracking bicycle interactions
* Author: Florian Winkler, Martin Moser, Lea Effertz
* Description: A model which shows how the interactions with other traffic participants affect a cyclists perception area, point of view and stress level.
* Based on the Simple Traffic Model and the concept of interaction of Luuk's model. 
* Tags:  cycling, eyetracking, traffic simulation, stress simulation
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
	
	file polygon_stats_objects <- file("../includes/polygons_object_counts.geojson");
	
	//set the GAMA coordinate reference system using the one of the building_file (Lambert zone II).
	geometry shape <- envelope(road_diff_edges);
	
	//initialize list to track the participants' parameters and a list for driveways
	list<bool> stress_list <- [];
    list<int> speed_list <- [];
    list<float> heart_rate_list <- [];
    list<geometry> out_intersections;
    
    //default values for parameters
    int people_nb <- 50;
    float people_speed <- 10.0;
    float part_speed <- 10.0;
    float stress;
    float heart_rate <- 120;
    int stressindicator;
    list<int> traffic_count <- [];
    int alert_duration <-5;
    int time_since_alert;
    list <int> stresscount;
    
//////// Initialisation ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	init {
		// Create graph from data for both the easy and difficult route
		create road from: road_diff_edges{
			// Create another road in the opposite direction and add aggregated edge attributes
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
		
		//initialize intersections and combine interesections
		list<geometry> all_difficult_intersections <- road_diff_nodes.contents;
		//write "all_difficult_intersections " + length(all_difficult_intersections);
		list<geometry> all_easy_intersections <- road_easy_nodes.contents;
		//write "all_easy_intersections " + length(all_easy_intersections);
		list<geometry> all_intersections <- union(all_difficult_intersections, all_easy_intersections);
		
		//write "All intersections combined " + length(all_intersections);
		
		
		create intersection from: road_diff_nodes;
		
		// Get intersections with street_count less than 2, where people / cars could randomly leave
		out_intersections <- intersection where (each.street_count < 2);
		write "Number of intersections with 'street_count' < 2: " + length(out_intersections);
		
		create DifficultBuildings from: difficultbuildings 
	    with: [elementId::int(read('full_id')), elementHeight::int(read('building_4')), elementColor::string(read('attrForGama'))];
	    
	    create road from: road_easy_edges{
			// Create another road in the opposite direction and add aggregated edge attributes
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
	    
		// define weighting of the graph
		map<road,float> weights_map <- road as_map (each:: (each.MOS_score_mean));
		// create weighted graph from roads (edges) and intersections (nodes)
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
	
	// create road user leaving a randomly sampled driveway (random intersection) every 10 cycles
	reflex create_new_person_leaving when: every(10 #cycles) {
		create people number: 1 with: (location: one_of(out_intersections).location);
		traffic_count <- [];
		add people to: traffic_count;
        }

}
/////// specifiy environment species ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// initialize intersections and specify behavior
species intersection skills: [intersection_skill] {
	bool is_traffic_signal;
	int street_count;
	string highway;
	
	reflex intersection_close{
		// Stop at intersections if it is within 5 meters
		ask cyclist at_distance (5){
			write "Cyclist if 5 meters from next intersection!";
			do action: stop_at_intersection;
		}
		// Change perception area if 20 meters from intersection
		ask cyclist at_distance (20) {
			do action: change_perception;
		}
	}
		
}

//create road species and specify behaviour
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
	

	// define grpahic representation of the road
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
    
}

/////// specify agent species //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species cyclist skills: [driving] {
	//specify default perception area 
	geometry perception_area <- circle(part_speed) intersection cone(0, 214);
	
	// default parameters
	bool stress <- false; //stress was chosen as boolean, since exact values are hard to quantify (due to gender and personal differences in participants)
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
	//the participants vitals are not affected and stay the default values and the person is relaxed and thereby not careful.
	reflex commute when: current_path != nil {
		do drive;
	}
	
	//Stop at intersections action
	 action stop_at_intersection{
    	speed <- 0.0;
    	write "Stopped";
    }
    
	//Scenario B: There is another traffic participant or obsatcle in the perception area of the cyclist:
	// the cyclist is now alerted and thereby careful and the vitals change depending on the number of 
	// other people in the perception area of the participant.
	reflex update {
        //count traffic in perception area
        int nearby_count <- length(traffic_count);
        write "There are " + nearby_count + " other traffic participants nearby.";
        
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
            // no other traffic detected results in reverting the paramters after duration
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
    
	
	aspect base {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
	}
	
    
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
		// inform the user about the values measured.
    	write "stress: " + stress_list;
    	write "speed: "+ speed_list;
    	write "heart_rate: " + heart_rate_list;
    }
    
    // update perception area
    reflex update_actionArea {
		perception_area <- circle(30) intersection cone(heading - 20, heading + 20);	
	}
    
    //change perception area at intersections or in close proximity to other cyclists
    action change_perception{
    	perception_area <- circle(15) intersection cone(heading - 41.7, heading + 41.7);
    }
	
	// visualisation of the agents and the participants perception area.
	aspect default {
		draw circle(5.0) color: color rotate: heading + 90 border: #black;
	}
	
	aspect perception_area {
		draw self.perception_area color: #goldenrod;
	}
		

}

// specify other people on the road
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
		ask cyclist at_distance (40){
			do action: change_perception;
			add 1 to: traffic_count;
		}
	}
	
	// visualisation
	aspect default {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
	}

}

////////// experiment visualisation ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

experiment difficult type: gui {
	//Parameters that can be changed by the user for different experiments
	parameter "Number of traffic participants" var: people_nb category:"Experiment parameters";
	parameter "Participants' speed" var: part_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	parameter "Others' speed" var: people_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	
	output {
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:perception_area transparency: 0.5;
			species road;
			species people;
			species DifficultBuildings aspect: basic;
			//species polygon_areas aspect: default;
		}
		// show the recorded vitals of the participant in charts
		display vitals background: #white {
			chart "Participants' stress and speed" type: series {
				data "Stress" value: stressindicator color: #red;
				data "Participants' speed" value: part_speed color: #green;
				//data "Stresscount" value: length(stresscount) color: #blue;
				//data "Timeduration" value: time_since_alert color: #blue;
				}
		}
		display heart background: #white {
			chart "Particpants heart-rate in BPM" type: series{
				data "Heart rate" value: heart_rate color: #orange;
				data "average heart rate" value: mean(heart_rate_list) color: #blue;
			}
		}
	

	}

}

experiment easy type: gui {
	//Parameters that can be changed by the user for different experiments
	parameter "Number of traffic participants" var: people_nb category:"Experiment parameters";
	parameter "Participants' speed" var: part_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	parameter "Others' speed" var: people_speed min: 0.0 max: 100.0 step: 0.5 category:"Experiment parameters";
	output {
		display map type:opengl{
			species cyclist;
	   		species cyclist aspect:perception_area transparency: 0.5;
			species road;
			species people;
			species EasyBuildings aspect: basic ; 
			//species polygon_areas aspect: default;
		}
		// show the recorded vitals of the participant in charts
		display map_3D background: #white {
			chart "Participants' stress and speed" type: series {
				data "Stress" value: stressindicator color: #red;
				data "Participants' speed" value: part_speed color: #green;
				//data "Stresscount" value: length(stresscount) color: #blue;
				//data "Timeduration" value: time_since_alert color: #blue;
				}	
		}
		display heart background: #white {
			chart "Particpants heart-rate in BPM" type: series{
				data "Heart rate" value: heart_rate color: #orange;
				data "average heart rate" value: mean(heart_rate_list) color: #blue;
			}
		}

	}

}


