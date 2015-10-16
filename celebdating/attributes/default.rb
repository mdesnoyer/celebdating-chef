
default[:celebdating][:root_path] = "/opt/neon/celebdating"
default[:celebdating][:log_dir] = "/mnt/neon/logs/celebdating"
default[:celebdating][:runuser] = "celebdating"
default[:celebdating][:port] = 80
default[:celebdating][:caffe_net_bucket] = "caffemodelsneon"
default[:celebdating][:caffe_net_path] = "age_deploy.prototxt"
default[:celebdating][:face_cluster_model_bucket] = "caffemodelsneon"
default[:celebdating][:face_cluster_model_path] = "agenet_iter_54000.caffemodel"
default[:celebdating][:celebrity_model_bucket] = "caffemodelsneon"
default[:celebdating][:celebrity_model_path] = "age_deploy.prototxt"
