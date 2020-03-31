#!/bin/bash -xe

# remove any previous artifacts
rm -rf output
rm -f ./*tar.gz

# Get the tarball
./build.sh dist

# create the src.rpm
rpmbuild \
    -D "_srcrpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    -ts ./*.gz

# install any build requirements
yum-builddep output/*src.rpm

# create the rpms
rpmbuild \
    -D "_rpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    --rebuild output/*.src.rpm

[[ -d exported-artifacts ]] || mkdir -p exported-artifacts
find output -iname \*rpm -exec mv "{}" exported-artifacts/ \;
mv *.tar.gz exported-artifacts


COLLECTION_NAME="ovirt_collection"
COLLECTION_NAMESPACE="ovirt"
# Replace @COLLECTION_NAMESPACE@ and @COLLECTION_NAME@ with correct names.
for file in $(git ls-files plugins/modules)
do
  sed -i "s/@COLLECTION_NAMESPACE@/$COLLECTION_NAMESPACE/g;s/@COLLECTION_NAME@/$COLLECTION_NAME/g;" $file
done

COLLECTION_DIR="/usr/local/share/ansible/collections/ansible_collections/$COLLECTION_NAMESPACE/$COLLECTION_NAME"
mkdir -p $COLLECTION_DIR
cp -r $PWD/* $COLLECTION_DIR
cd $COLLECTION_DIR
ansible-test sanity --test validate-modules --test pep8
