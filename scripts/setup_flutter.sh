#!bin/bash

read -p "Enter name of the Flutter project (in snake_case, e.g: my_app): " APP_NAME 

if [[ -z "$APP_NAME" ]]; then
  echo "Error: The project name cannot be empty."
  exit 1
fi

echo "Creating a Flutter project $APP_NAME"

cd "$APP_NAME" || exit

echo "Generating folder and file structure inside lib/..."

FILES=(
  # Entry points
  "lib/main_development.dart"
  "lib/main_staging.dart"
  "lib/main_production.dart"

  # Config
  "lib/config/app_config.dart"
  "lib/config/environment.dart"
  "lib/config/constants/api_constants.dart"
  "lib/config/constants/app_constants.dart"

  # Core
  "lib/core/errors/exceptions.dart"
  "lib/core/errors/failures.dart"
  "lib/core/network/api_client.dart"
  "lib/core/network/network_info.dart"
  "lib/core/themes/app_theme.dart"
  "lib/core/themes/app_colors.dart"
  "lib/core/utils/validators.dart"
  "lib/core/utils/extensions.dart"
  "lib/core/utils/helpers.dart"
  "lib/core/routing/app_router.dart"
  "lib/core/routing/routes.dart"
  "lib/core/routing/route_guards.dart"

  # Features - Auth
  "lib/features/auth/data/datasources/remote/auth_remote_datasource.dart"
  "lib/features/auth/data/datasources/local/auth_local_datasource.dart"
  "lib/features/auth/data/models/user_model.dart"
  "lib/features/auth/data/models/login_request_model.dart"
  "lib/features/auth/data/repositories/auth_repository_impl.dart"
  "lib/features/auth/domain/entities/user.dart"
  "lib/features/auth/domain/repositories/auth_repository.dart"
  "lib/features/auth/domain/usecases/login_usecase.dart"
  "lib/features/auth/domain/usecases/logout_usecase.dart"
  "lib/features/auth/domain/usecases/get_current_user_usecase.dart"
  "lib/features/auth/presentation/cubit/auth_cubit.dart"
  "lib/features/auth/presentation/cubit/auth_state.dart"
  "lib/features/auth/presentation/screens/login_screen.dart"
  "lib/features/auth/presentation/screens/register_screen.dart"
  "lib/features/auth/presentation/widgets/login_form.dart"
  "lib/features/auth/presentation/widgets/auth_button.dart"

  # Features - Home & Profile
  "lib/features/home/data/.gitkeep"
  "lib/features/home/domain/.gitkeep"
  "lib/features/home/presentation/.gitkeep"
  "lib/features/profile/data/.gitkeep"
  "lib/features/profile/domain/.gitkeep"
  "lib/features/profile/presentation/.gitkeep"

  # Shared
  "lib/shared/widgets/buttons/.gitkeep"
  "lib/shared/widgets/inputs/.gitkeep"
  "lib/shared/widgets/loading_indicator.dart"
  "lib/shared/mixins/validation_mixin.dart"
  "lib/shared/extensions/context_extensions.dart"

  # Injection
  "lib/injection/injection_container.dart"
  "lib/injection/injection_container.config.dart"

  # Generated
  "lib/generated/localization/.gitkeep"
  "lib/generated/assets/.gitkeep"
)

for filepath in "$FILES[@]"
do
  mkdir -p "$(dirmane "$filepath")"
  touch "$filepath"
done

echo "Clean architecture successfully generated in '$APP_NAME/lib/'."

tree "$APP_NAME/lib"
