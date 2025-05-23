# deploy Istio on a Minikube cluster.  
minikube start
minikube addons enable istio-provisioner
minikube addons enable istio

cd Deployments
kubectl apply -f mtls2.yaml
# kubectl apply -f mtls.yaml #uncomment this for mTLS with Istio authentication policy

kubectl apply -f mongo-config.yaml
kubectl apply -f mongo-secret.yaml #change it to mongo-sealed-secret.yaml after setiing up sealed-secrets
kubectl apply -f mongo-img.yaml
kubectl apply -f webapp.yaml
kubectl apply -f test-pod.yaml

minikube service webapp-service