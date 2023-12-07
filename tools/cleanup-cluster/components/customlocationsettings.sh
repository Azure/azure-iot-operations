echo "##############################################################"
echo "I'm customlocationsettings.sh"

kubectl get -A Customlocationsettings -o name | xargs -I {} kubectl -n azure-arc delete {}

echo ""
kubectl get -A Customlocationsettings 