#Datadog Agent For EngineYard

## How to use this recipe

1. Add the whole dir `custom-datadog` to your cookbooks dir;
2. On `cookbooks/ey-custom/recipes/after-main.rb` add `include_recipe 'custom-datadog'
`;
3. Edit `attributes/default` with your api_key and site name;
4. Upload recipe and apply

